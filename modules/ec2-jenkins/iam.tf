resource "aws_iam_role" "iam_role" {
  name = var.jenkins-ec2-role-name
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

resource "aws_iam_role_policy_attachment" "iam-policy" {
  role       = aws_iam_role.iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "ec2-instance-profile" {
  name = var.jenkins-ec2-instance-profile-name
  role = aws_iam_role.iam_role.name
}
