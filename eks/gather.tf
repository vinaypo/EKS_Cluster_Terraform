data "aws_eks_cluster" "eks" {
  name = "${local.env}-${var.cluster-name}"

  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "eks_cluster_auth" {
  name = "${local.env}-${var.cluster-name}"

  depends_on = [module.eks]
}

data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = ["${local.env}-${var.vpc-name}"]
  }
}
