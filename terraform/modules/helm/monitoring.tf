
resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
  }
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

  create_namespace = false
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
