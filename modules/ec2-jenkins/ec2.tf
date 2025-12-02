resource "aws_instance" "jenkins-server" {
  ami                         = lookup(var.ami-id, var.region)
  instance_type               = var.jenkins-ec2-instance-type
  subnet_id                   = var.public-subnet_id
  vpc_security_group_ids      = [var.jenkins-ec2-sg-id]
  associate_public_ip_address = true
  key_name                    = var.key-name
  iam_instance_profile        = aws_iam_instance_profile.ec2-instance-profile.name
  root_block_device {
    volume_size = 30
  }
  user_data = base64encode(file(var.jenkins_install))
  tags = {
    Name = var.jenkins-ec2-name
    Env  = var.env
  }
  lifecycle {
    create_before_destroy = true
  }
}
