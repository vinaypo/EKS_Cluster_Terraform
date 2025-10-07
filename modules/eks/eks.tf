# Create EKS Cluster
resource "aws_eks_cluster" "eks" {
  count    = var.is_eks_cluster_enabled ? 1 : 0
  name     = var.cluster-name
  role_arn = aws_iam_role.eks-role[count.index].arn
  version  = var.cluster-version

  vpc_config {
    subnet_ids              = data.aws_subnets.private_subnets.ids
    endpoint_private_access = var.endpoint-private-access
    endpoint_public_access  = var.endpoint-public-access
    security_group_ids      = [data.aws_security_group.eks-cluster-sg.id]
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }
  tags = {
    Name = var.cluster-name
    env  = var.env
  }
}

# OIDC Provider for EKS Cluster
resource "aws_iam_openid_connect_provider" "eks-oidc" { # Create OIDC provider for EKS cluster to enable IAM roles for service accounts
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks-certificate.certificates[0].sha1_fingerprint] # Fetch the thumbprint from the TLS certificate data source
  url             = data.tls_certificate.eks-certificate.url                                # Fetch the URL from the TLS certificate data source
}

# Add-Ons for EKS Cluster
resource "aws_eks_addon" "eks-addons" {
  for_each      = { for idx, addon in var.addons : idx => addon }
  cluster_name  = aws_eks_cluster.eks[0].name
  addon_name    = each.value.name
  addon_version = each.value.version

  depends_on = [
    aws_eks_node_group.ondemand-node,
    aws_eks_node_group.spot-node
  ]
}

# Node Group for EKS Cluster--On-Demand Instances
resource "aws_eks_node_group" "ondemand-node" {
  cluster_name    = aws_eks_cluster.eks[0].name
  node_group_name = "${var.cluster-name}-ondemand-nodes"
  node_role_arn   = aws_iam_role.eks-nodegroupe-role[0].arn
  subnet_ids      = data.aws_subnets.private_subnets.ids
  scaling_config {
    desired_size = var.desired_capacity_ondemand
    max_size     = var.max_size_ondemand
    min_size     = var.min_size_ondemand
  }
  instance_types = var.ondemand_instance_types
  capacity_type  = "ON_DEMAND"
  labels = {
    type = "ondemand"
  }
  update_config {
    max_unavailable = 1
  }
  tags = {
    Name = "${var.cluster-name}-ondemand-nodes"
    env  = var.env
  }
  depends_on = [aws_eks_cluster.eks]
}

#Node Group for EKS Cluster--Spot Instances
resource "aws_eks_node_group" "spot-node" {
  cluster_name    = aws_eks_cluster.eks[0].name
  node_group_name = "${var.cluster-name}-spot-nodes"
  node_role_arn   = aws_iam_role.eks-nodegroupe-role[0].arn
  subnet_ids      = data.aws_subnets.private_subnets.ids
  scaling_config {
    desired_size = var.desired_capacity_spot
    max_size     = var.max_size_spot
    min_size     = var.min_size_spot
  }
  instance_types = var.spot_instance_types
  capacity_type  = "SPOT"
  labels = {
    type      = "spot"
    lifecycle = "spot"
  }
  disk_size = 50
  update_config {
    max_unavailable = 1
  }
  tags = {
    Name = "${var.cluster-name}-spot-nodes"
    env  = var.env
  }
  depends_on = [aws_eks_cluster.eks]
}
