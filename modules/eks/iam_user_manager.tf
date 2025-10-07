resource "aws_iam_role" "eks-admin" {
  name = "${local.cluster-name}-admin-role-${random_integer.suffix.result}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" # allow account users to assume, policy restricts further
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "eks-admine-policy" {
  name = "${local.cluster-name}-AmazonEKSAdminPolicy-${random_integer.suffix.result}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:*"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action = [
          "iam:PassRole"
        ],
        Resource = "*",
        Effect   = "Allow",
        Condition = {
          "StringEquals" : {
            "iam:PassedToService" : "eks.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks-admin-policy_attachment" {
  role       = aws_iam_role.eks-admin.name
  policy_arn = aws_iam_policy.eks-admine-policy.arn
}

resource "aws_iam_policy" "eksadmin-assume_role_policy" {
  name = "${local.cluster-name}-AdminAssumeEKSRolePolicy-${random_integer.suffix.result}"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = "${aws_iam_role.eks-admin.arn}"
      }
    ]
  })
}

resource "aws_iam_user" "manager" {
  name = "manager"
}

resource "aws_iam_user_policy_attachment" "eks-admin-assumepolicy" {
  user       = aws_iam_user.manager.name
  policy_arn = aws_iam_policy.eksadmin-assume_role_policy.arn
}

resource "aws_eks_access_entry" "admin-access" {
  kubernetes_groups = ["my-admin"]
  principal_arn     = aws_iam_role.eks-admin.arn
  cluster_name      = aws_eks_cluster.eks[0].name
}


# then create a iam security access key and secret key for the user and configure kubectl with those credentials to access the cluster
# "aws configure --profile manager"
# aws sts assume-role --role-arn <role_arn> --role-session-name eks-admin-session --profile manager
# next edit vim ~/.aws/config and add other profie like shown below
# [profile manager]

# [profile eks-admin]
# role_arn=<iam role of eksadminrole>
# source_profile=manager

# "aws eks --region us-east-1 update-kubeconfig --name <cluster-name> --profile eks-admin"

# before running the above command, need to create the role and rolebinding in the cluster where the iam group is mapped to the kubernetes group
