resource "aws_iam_role" "cluster_admin" {
  name = "${local.cluster-name}-admin-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"

      Principal = {
        AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/User1"
      }

      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "cluster_admin_assume_role" {
  name = "${local.cluster-name}-cluster-admin-assume-role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sts:AssumeRole"
      Resource = aws_iam_role.cluster_admin.arn
    }]
  })
}

resource "aws_iam_user_policy_attachment" "cluster_admin_assume_role" {
  user       = "User1"
  policy_arn = aws_iam_policy.cluster_admin_assume_role.arn
}

resource "aws_eks_access_entry" "cluster_admin" {
  cluster_name  = aws_eks_cluster.eks[0].name
  principal_arn = aws_iam_role.cluster_admin.arn
  depends_on = [
    aws_eks_cluster.eks[0]
  ]
}

# Associate the cluster admin role with the AmazonEKSClusterAdminPolicy
# this is the new way to give access to the cluster  using EKS Access Control without using role binding and kubectl apply. This is a more secure way to give access to the cluster admin role.
resource "aws_eks_access_policy_association" "cluster_admin" {
  cluster_name  = aws_eks_cluster.eks[0].name
  principal_arn = aws_iam_role.cluster_admin.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [
    aws_eks_access_entry.cluster_admin
  ]
}

# aws configure --profile User1
# # aws sts assume-role \
#   --role-arn arn:aws:iam::741448944841:role/prod-eks-cluster-admin-role \
#   --role-session-name test \
#   --profile User1
# aws eks update-kubeconfig --region us-east-1 --name <cluster-name> --role-arn <cluster-admin-role-arn> --alias admin --user-alias eks-admin --profile User1
