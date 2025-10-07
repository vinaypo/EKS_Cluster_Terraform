locals {
  env = var.env
}

module "eks" {
  source                    = "../modules/eks"
  cluster-name              = "${local.env}-${var.cluster-name}"
  vpc-name                  = "${local.env}-${var.vpc-name}"
  is_eks_role_enabled       = var.is_eks_role_enabled
  is_eks_node_role_enabled  = var.is_eks_node_role_enabled
  is_eks_cluster_enabled    = var.is_eks_cluster_enabled
  cluster-version           = var.cluster-version
  endpoint-private-access   = var.endpoint-private-access
  endpoint-public-access    = var.endpoint-public-access
  eks-sg-name               = "${local.env}-${var.eks-sg-name}"
  addons                    = var.addons
  desired_capacity_ondemand = var.desired_capacity_ondemand
  desired_capacity_spot     = var.desired_capacity_spot
  max_size_ondemand         = var.max_size_ondemand
  max_size_spot             = var.max_size_spot
  min_size_ondemand         = var.min_size_ondemand
  min_size_spot             = var.min_size_spot
  ondemand_instance_types   = var.ondemand_instance_types
  spot_instance_types       = var.spot_instance_types
  env                       = var.env

}
