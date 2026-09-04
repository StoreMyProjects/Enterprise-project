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