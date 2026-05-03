resource "aws_iam_role" "ebs_csi" {
  name = "${var.cluster_name}-ebs-csi-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_attach" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = var.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi.arn
}

resource "aws_iam_policy" "alb_controller" {
  name   = "${var.cluster_name}-alb-controller-policy"
  policy = file("${path.module}/iam_policy.json")
}

data "aws_iam_openid_connect_provider" "oidc" {
  arn = var.oidc_provider_arn
}

resource "aws_iam_role" "alb_controller" {
  name = "${var.cluster_name}-alb-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(var.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "alb_attach" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}

resource "kubernetes_service_account_v1" "alb" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller.arn
    }
  }
}

resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  depends_on = [kubernetes_service_account_v1.alb]

  set = [
    {
      name  = "clusterName"
      value = var.cluster_name
    },
    {
      name  = "serviceAccount.create"
      value = "false"
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    },
    {
      name  = "region"
      value = var.region
    }
  ]
}

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"

  depends_on = [helm_release.alb_controller]
}

resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"

  create_namespace = true

  timeout = 600

  values = [yamlencode({
    server = {
      service = {
        type = "ClusterIP"
      # type = "LoadBalancer"
      #   annotations = {
      #   "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
      # }
      }
      extraArgs = [
      "--insecure"
    ]
    }
  })]
  
}

resource "kubernetes_secret_v1" "alertmanager_config" {
  metadata {
    name      = "alertmanager-config"
    namespace = "monitoring"
  }

  data = {
    "alertmanager.yaml" = <<-EOT
global:
  resolve_timeout: 5m

route:
  receiver: slack-warning       # this is default receiver
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 30s
  repeat_interval: 1m

  routes:
    - match:
        severity: critical
      receiver: slack-critical

    - match:
        severity: warning
      receiver: slack-warning

receivers:
  - name: slack-critical
    slack_configs:
      - api_url: ${var.slack_critical_webhook_url}
        channel: "#alerts-critical"
        title: "🚨 CRITICAL: {{ .CommonLabels.alertname }}"
        text: "{{ range .Alerts }}{{ .Annotations.summary }}\n{{ end }}"
        send_resolved: true

  - name: slack-warning
    slack_configs:
      - api_url: ${var.slack_warning_webhook_url}
        channel: "#alerts-warning"
        title: "⚠️ WARNING: {{ .CommonLabels.alertname }}"
        text: "{{ range .Alerts }}{{ .Annotations.summary }}\n{{ end }}"
        send_resolved: true
EOT
  }

  type = "Opaque"
}

resource "helm_release" "monitoring" {
  name       = "kube-prometheus-stack"
  namespace  = "monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"

  create_namespace = true
  timeout          = 600

  values = [yamlencode({
    grafana = {
      enabled = true

      adminPassword = var.grafana_admin_password

      service = {
        type = "ClusterIP"
      }
    }

    prometheus = {
      prometheusSpec = {
        resources = {
          requests = {
            cpu    = "200m"
            memory = "512Mi"
          }
        }
      }
    }

    alertmanager = {
      alertmanagerSpec = {
        resources = {
          requests = {
            cpu    = "100m"
            memory = "256Mi"
          }
        }
        configSecret = "alertmanager-config"
      }
    }
  })]
  depends_on = [
    kubernetes_secret_v1.alertmanager_config
  ]
}