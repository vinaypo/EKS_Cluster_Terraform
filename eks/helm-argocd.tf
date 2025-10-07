resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "5.24.1"
  namespace        = "argocd"
  create_namespace = true
  set = [{
    name  = "server.service.type"
    value = "LoadBalancer"
    },

    {
      name  = "server.ingress.enabled"
      value = "false"
  }]

  depends_on = [
    helm_release.aws_load_balancer_controller
  ]
}
