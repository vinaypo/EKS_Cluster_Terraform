data "aws_eks_cluster_auth" "eks" {
  name       = module.eks.cluster-name
  depends_on = [module.eks]
}

data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = ["${local.env}-${var.vpc-name}"]
  }
}
