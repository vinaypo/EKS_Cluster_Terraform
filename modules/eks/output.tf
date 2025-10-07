output "oidc-arn" {
  value = aws_iam_openid_connect_provider.eks-oidc.arn
}
output "oidc-url" {
  value = aws_iam_openid_connect_provider.eks-oidc.url
}
