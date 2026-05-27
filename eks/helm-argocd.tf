resource "helm_release" "argocd" {
  name             = "${local.env}-argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "9.4.0"
  namespace        = "argocd"
  create_namespace = true
  # set = [{
  #   name  = "server.service.type" #for normal project
  #   value = "LoadBalancer"
  #   },

  #   {
  #     name  = "server.ingress.enabled"
  #     value = "false"
  #   }
  # ]
  values = [
    file("${path.module}/values/argocd/argocd-values-9.4.0.yaml")
  ]


  depends_on = [
    helm_release.aws_load_balancer_controller
  ]
}
