locals {
  cluster-name = var.cluster-name
}

resource "random_integer" "suffix" {
  min = 1000
  max = 9999
}

resource "aws_iam_role" "eks-role" {
  count = var.is_eks_role_enabled ? 1 : 0 #ternary operator to create role based on condition
  name  = "${local.cluster-name}-eks-role-${random_integer.suffix.result}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" { # this policy is required for EKS Cluster to access other AWS services
  count      = var.is_eks_role_enabled ? 1 : 0
  role       = aws_iam_role.eks-role[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "eks-nodegroupe-role" {
  count = var.is_eks_node_role_enabled ? 1 : 0
  name  = "${local.cluster-name}-nodegroup-role-${random_integer.suffix.result}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" { # this policy is required for EKS Node Group to manage worker nodes in the cluster
  count      = var.is_eks_node_role_enabled ? 1 : 0
  role       = aws_iam_role.eks-nodegroupe-role[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" { # this policy is required for EKS Node Group to manage the Amazon VPC CNI plugin
  count      = var.is_eks_node_role_enabled ? 1 : 0
  role       = aws_iam_role.eks-nodegroupe-role[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" { # this policy is required for EKS Node Group to pull container images from Amazon ECR
  count      = var.is_eks_node_role_enabled ? 1 : 0
  role       = aws_iam_role.eks-nodegroupe-role[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "AmazonEBS_CSI_Driver_Policy" { # this policy is required for EKS Node Group to manage the Amazon EBS CSI Driver
  count      = var.is_eks_node_role_enabled ? 1 : 0
  role       = aws_iam_role.eks-nodegroupe-role[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_iam_role" "eks_oidc" {
  assume_role_policy = data.aws_iam_policy_document.eks_oidc_assume_role_policy.json # assume role policy from gather.tf file for assuming role using OIDC token
  name               = "eks-oidc"
}

resource "aws_iam_policy" "eks-oidc-policy" {
  name = "test-policy"

  policy = jsonencode({
    Statement = [{
      Action = [
        "s3:ListAllMyBuckets",
        "s3:GetBucketLocation",
        "*"
      ]
      Effect   = "Allow"
      Resource = "*"
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks-oidc-policy-attach" {
  role       = aws_iam_role.eks_oidc.name
  policy_arn = aws_iam_policy.eks-oidc-policy.arn
}

# OIDC Issuer → The EKS cluster URL that issues signed JWT tokens for service accounts.

# OIDC Provider (IAM) → The AWS IAM resource that tells AWS to trust the EKS issuer and its TLS cert.

# TLS Thumbprint → Ensures AWS only trusts the real OIDC issuer, not a spoofed one.

# sts:AssumeRoleWithWebIdentity → Lets a pod use an OIDC token by EKS instead of AWS keys to assume an IAM role.

# Trust Policy (with sub) → Restricts which Kubernetes service account (e.g., default/aws-test) can use the IAM role.

# IAM Role → The AWS identity the pod temporarily assumes.

# IAM Policy → The permissions the pod gets once it assumes the IAM role (e.g., access to S3).

# Flow → Pod gets OIDC token → AWS STS validates via provider & TLS → STS issues temp creds → Pod uses creds to access AWS services.

# ---

# Your pod is assuming an IAM Role through IRSA (IAM Roles for Service Accounts).
# IRSA works by linking:

# 1. A Kubernetes ServiceAccount

# → annotated with an IAM role ARN.

# 2. An OIDC token issued by Kubernetes

# → passed to AWS STS.

# 3. An IAM Role trust policy

# → allowing that service account to assume the role.

# 4. AWS STS returns temporary credentials

# → used by the pod when calling AWS APIs.
