resource "aws_iam_user" "manager" {
  name = "manager"
}

resource "aws_iam_role" "eks-readonlyadmin" {
  name = "${local.cluster-name}-readonlyadmin-role-${random_integer.suffix.result}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_user.manager.arn # allow account users to assume, policy restricts further
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "manager_describe_cluster" {
  name = "${local.cluster-name}-describe-cluster-${random_integer.suffix.result}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"

      Action = [
        "eks:DescribeCluster"
      ]

      Resource = aws_eks_cluster.eks[0].arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "manager_describe_cluster" {
  role       = aws_iam_role.eks-readonlyadmin.name
  policy_arn = aws_iam_policy.manager_describe_cluster.arn
}

resource "aws_iam_policy" "eks-readonlyadmin-assume_role_policy" {
  name = "${local.cluster-name}-AdminAssumeEKSRolePolicy-${random_integer.suffix.result}"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = "${aws_iam_role.eks-readonlyadmin.arn}"
      }
    ]
  })
}


resource "aws_iam_user_policy_attachment" "eks-readonlyadmin-assumepolicy" {
  user       = aws_iam_user.manager.name
  policy_arn = aws_iam_policy.eks-readonlyadmin-assume_role_policy.arn
}



resource "aws_eks_access_entry" "readonlyadmin-access" {
  principal_arn = aws_iam_role.eks-readonlyadmin.arn
  cluster_name  = aws_eks_cluster.eks[0].name
  depends_on = [
    aws_eks_cluster.eks[0]
  ]
}


resource "aws_eks_access_policy_association" "readonlycluster_admin" {
  cluster_name  = aws_eks_cluster.eks[0].name
  principal_arn = aws_iam_role.eks-readonlyadmin.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [
    aws_eks_access_entry.readonlyadmin-access
  ]
}


# aws configure --profile manager-base
# edit ~/.aws/config and add other profile like shown below

# [profile manager]
# role_arn = arn:aws:iam::741448944841:role/prod-eks-cluster-readonlyadmin-role-1646
# source_profile = manager-base
# region = us-east-1

# aws sts get-caller-identity --profile manager


# # aws eks update-kubeconfig \
#   --region us-east-1 \
#   --name prod-eks-cluster \
#   --alias manager-readonly \
#   --user-alias manager \
#   --profile manager


