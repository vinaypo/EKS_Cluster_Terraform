resource "helm_release" "metrics-server" {
  name = "metrics-server"

  repository       = "https://kubernetes-sigs.github.io/metrics-server/"
  chart            = "metrics-server"
  namespace        = "monitoring"
  create_namespace = true
  version          = "3.13.0"

  set = [
    {
      name  = "args[0]"
      value = "--kubelet-insecure-tls"
    },
    {
      name  = "args[1]"
      value = "--metric-resolution=15s"
    }
  ]

  depends_on = [helm_release.aws_load_balancer_controller]
}
