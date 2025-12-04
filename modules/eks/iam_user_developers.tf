data "aws_caller_identity" "current" {} # To get current account ID

resource "aws_iam_group" "developers" { # Create an IAM group named 'developers'
  name = "grp-developers"
  path = "/users/"
}

resource "aws_iam_user" "user1" { # Create an IAM user 
  name = "user-1"
}

resource "aws_iam_user_group_membership" "user1_group" { # Add the user to the developers group
  user   = aws_iam_user.user1.name
  groups = [aws_iam_group.developers.name]
}


resource "aws_iam_role" "developers_role" { # Create an IAM role for developers 
  name = "${local.cluster-name}-developers-role-${random_integer.suffix.result}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" # The role being assumed must trust the user/principal.
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "developers_eks_policy" { # Policy for EKS developers role to allow EKS actions
  name = "${local.cluster-name}-AmazonEKSDevelopersPolicy-${random_integer.suffix.result}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "developers_role_attach" { # Attach the EKS policy to the developers role
  role       = aws_iam_role.developers_role.name
  policy_arn = aws_iam_policy.developers_eks_policy.arn
}

resource "aws_iam_policy" "developers_assume_role_policy" { # Policy to allow developers group to assume the developers role
  name        = "${local.cluster-name}-DevelopersAssumeEKSRolePolicy-${random_integer.suffix.result}"
  description = "Allow developers group to assume EKS role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = "${aws_iam_role.developers_role.arn}" # The user/principal must be allowed to call sts:AssumeRole.
      }
    ]
  })
}
# Both sides must agree — the user must be allowed to assume, and the role must trust the user.

resource "aws_iam_group_policy_attachment" "developers_group_attach" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.developers_assume_role_policy.arn
}

resource "aws_eks_access_entry" "developers-access" {
  cluster_name      = aws_eks_cluster.eks[0].name      # Reference the EKS cluster created in eks.tf
  principal_arn     = aws_iam_role.developers_role.arn # ARN of the IAM role to be mapped
  kubernetes_groups = ["my-viewers"]                   # Kubernetes group to map the IAM group to
}

# then create a iam security access key and secret key for the user and configure kubectl with those credentials to access the cluster
# "aws configure --profile developers"
# aws sts assume-role --role-arn <role_arn> --role-session-name developers-session --profile developers
# next edit vim ~/.aws/config and add other profie like shown below
# [profile developers]

# [profile user-1]
# role_arn=<iam role of developerrole>
# source_profile=developers

# "aws eks --region us-east-1 update-kubeconfig --name <cluster-name> --profile user-1"

# before running the above command, need to create the role and rolebinding in the cluster where the iam group is mapped to the kubernetes group
