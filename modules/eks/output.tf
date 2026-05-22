output "cluster-name" {
  value = aws_eks_cluster.eks[0].name
}
output "cluster_endpoint" {
  value = aws_eks_cluster.eks[0].endpoint
}
output "cluster_certificate_data" {
  value = aws_eks_cluster.eks[0].certificate_authority[0].data
}
