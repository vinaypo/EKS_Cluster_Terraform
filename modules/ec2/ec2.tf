resource "aws_instance" "bastion-server" {
  ami                         = lookup(var.ami-id, var.region)
  instance_type               = var.ec2-instance-type
  subnet_id                   = var.public-subnet_id
  vpc_security_group_ids      = [var.ec2-sg-id]
  associate_public_ip_address = true
  key_name                    = var.key-name
  iam_instance_profile        = aws_iam_instance_profile.ec2-instance-profile.name

  root_block_device {
    volume_size = 30
  }
  # user_data = file("${path.root}/../${var.env}/install.sh.tpl", {
  #   github_pat = var.github_pat
  # })
  user_data = file("${path.root}/../${var.env}/install.sh")
  tags = {
    Name = var.ec2-name
    Env  = var.env
  }
  lifecycle {
    create_before_destroy = true
  }
}
