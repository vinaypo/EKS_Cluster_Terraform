resource "helm_release" "prometheus-helm" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "62.3.1"
  namespace  = "monitoring"

  timeout = 2000

  set = [{
    name  = "podSecurityPolicy.enabled"
    value = true
    },

    {
      name  = "server.persistentVolume.enabled"
      value = true
    },

    {
      name  = "grafana.service.type"
      value = "LoadBalancer"
    },

    {
      name  = "prometheus.service.type"
      value = "LoadBalancer"
  }]

  depends_on = [helm_release.metrics-server]
}
