module "Ec2-Instance" {
  source = "../modules/ec2"

  env                       = var.env
  region                    = var.aws-region
  ami-id                    = var.ami-id
  ec2-name                  = "${local.env}-${var.ec2-name}"
  ec2-instance-type         = var.ec2-instance-type
  key-name                  = var.key-name
  public-subnet_id          = module.vpc.public_subnet_ids[0]
  ec2-sg-id                 = module.vpc.ec2_sg_id
  user                      = var.user
  connection_type           = var.connection_type
  private_key               = var.private_key
  src                       = var.src
  destination               = var.destination
  commands                  = var.commands
  ec2-instance-profile-name = var.ec2-instance-profile-name
  ec2-role-name             = var.ec2-role-name
  ec2-policy-name           = var.ec2-policy-name

}
