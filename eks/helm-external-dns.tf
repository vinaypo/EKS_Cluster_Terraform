resource "helm_release" "external-dns" {
  name             = "external-dns"
  repository       = "https://kubernetes-sigs.github.io/external-dns/"
  chart            = "external-dns"
  version          = "1.20.0"
  namespace        = "external-dns"
  create_namespace = true

  values = [
    file("${path.module}/../values/external-dns/external-dns-values-1.20.0.yaml")
  ]

  depends_on = [aws_eks_pod_identity_association.external_dns_association]
}
