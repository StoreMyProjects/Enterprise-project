
resource "helm_release" "argo_rollouts" {
  name      = "argo-rollouts"
  namespace = "argo-rollouts"

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-rollouts"

  create_namespace = true
  timeout          = 600
}