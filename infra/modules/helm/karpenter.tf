data "aws_iam_role" "karpenter_node_group" {
  name = var.node_group_role_name
}

resource "aws_iam_policy" "karpenter_controller" {
  name = "KarpenterControllerPolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Karpenter"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ec2:DescribeImages",
          "ec2:RunInstances",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeSpotPriceHistory",
          "ec2:CreateTags",
          "ec2:DeleteLaunchTemplate",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:DescribeFleetHistory",
          "ec2:DescribeFleetInstances",
          "ec2:DescribeVolumes",
          "ec2:DescribeVpcs",
          "eks:DescribeCluster"
        ],
        Resource = "*"
      },
      {
        Sid    = "PassNodeIAMRole"
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ],
        Resource = data.aws_iam_role.karpenter_node_group.arn,
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ec2.amazonaws.com"
          }
        }
      },
      {
        Sid    = "ManageKarpenterInstanceProfiles"
        Effect = "Allow"
        Action = [
          "iam:AddRoleToInstanceProfile",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:GetInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:TagInstanceProfile"
        ]
        Resource = "arn:aws:iam::*:instance-profile/${var.cluster_name}_*"
      },
      {
        Sid    = "InterruptionQueue"
        Effect = "Allow"
        Action = [
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ReceiveMessage"
        ],
        Resource = "arn:aws:sqs:*:*:karpenter-*"
      }
    ]
  })
}

resource "aws_iam_role" "karpenter_controller" {
  name = "karpenter-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_controller_attach" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_controller.arn
}

resource "kubernetes_namespace_v1" "karpenter" {
  metadata {
    name = "karpenter"
  }
}

resource "aws_eks_pod_identity_association" "karpenter" {
  cluster_name    = var.cluster_name
  namespace       = kubernetes_namespace_v1.karpenter.metadata[0].name
  service_account = "karpenter"
  role_arn        = aws_iam_role.karpenter_controller.arn
}

resource "helm_release" "karpenter_crd" {
  name       = "karpenter-crd"
  namespace  = kubernetes_namespace_v1.karpenter.metadata[0].name
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter-crd"
  version    = "1.0.8"

  create_namespace = false
  timeout          = 600

  depends_on = [
    kubernetes_namespace_v1.karpenter,
    helm_release.alb_controller
  ]
}

resource "helm_release" "karpenter" {
  name       = "karpenter"
  namespace  = kubernetes_namespace_v1.karpenter.metadata[0].name
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "1.0.8"

  create_namespace = false
  wait             = true
  timeout          = 600

  depends_on = [
    aws_eks_pod_identity_association.karpenter,
    helm_release.karpenter_crd,
    helm_release.alb_controller
  ]

  values = [yamlencode({
    settings = {
      clusterName       = var.cluster_name
      clusterEndpoint   = var.cluster_endpoint
      interruptionQueue = ""
    }

    controller = {
      resources = {
        requests = {
          cpu    = "100m"
          memory = "256Mi"
        }
      }
      serviceAccount = {
        create = true
        name   = "karpenter"
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.karpenter_controller.arn
        }
      }
    }

    nodeSelector = {
      "kubernetes.io/os" = "linux"
    }
  })]
}

resource "kubectl_manifest" "karpenter_node_pool" {
  yaml_body = yamlencode({
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      name = "default"
    }
    spec = {
      template = {
        spec = {
          requirements = [
            {
              key      = "karpenter.k8s.aws/instance-family"
              operator = "In"
              values   = ["t3"]
            },
            {
              key      = "karpenter.k8s.aws/instance-size"
              operator = "In"
              values   = ["small"]
            },
            {
              key      = "topology.kubernetes.io/zone"
              operator = "In"
              values   = ["ap-south-1a", "ap-south-1b"]
            },
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["amd64"]
            },
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["on-demand"]
            }
          ]
          nodeClassRef = {
            group = "karpenter.k8s.aws"
            kind  = "EC2NodeClass"
            name  = "default"
          }
        }
      }
      limits = {
        cpu = "4"
      }
      disruption = {
        consolidationPolicy = "WhenEmptyOrUnderutilized"
        consolidateAfter    = "1m"
        expireAfter         = "168h"
      }
    }
  })

  depends_on = [
    helm_release.karpenter,
    kubectl_manifest.karpenter_node_class
  ]
}

resource "kubectl_manifest" "karpenter_node_class" {
  yaml_body = yamlencode({
    apiVersion = "karpenter.k8s.aws/v1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "default"
    }
    spec = {
      amiSelectorTerms = [{
        alias = "al2023@latest"
      }]
      role = var.node_group_role_name
      subnetSelectorTerms = [
        for subnet_id in var.private_subnet_ids : {
          id = subnet_id
        }
      ]
      securityGroupSelectorTerms = [{
        id = var.node_security_group_id
      }]
      tags = {
        "Name"        = "karpenter-node"
        "Environment" = "dev"
      }
    }
  })

  depends_on = [helm_release.karpenter]
}
