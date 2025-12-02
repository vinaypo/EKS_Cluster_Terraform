locals {
  env = var.env
}
module "vpc" {
  source = "../modules/vpc"

  env                 = var.env
  cidr-block          = var.cidr-block
  vpc-name            = "${local.env}-${var.vpc-name}"
  igw-name            = var.igw-name
  pub-subnet-count    = var.pub-subnet-count
  pub-cidr-block      = var.pub-cidr-block
  pub-sub-name        = "${local.env}-${var.pub-sub-name}"
  pri-subnet-count    = var.pri-subnet-count
  pri-cidr-block      = var.pri-cidr-block
  pri-sub-name        = "${local.env}-${var.pri-sub-name}"
  public-rt-name      = "${local.env}-${var.public-rt-name}"
  ngw-eip-name        = "${local.env}-${var.ngw-eip-name}"
  ngw-name            = "${local.env}-${var.ngw-name}"
  private-rt-name     = "${local.env}-${var.private-rt-name}"
  cluster-name        = "${local.env}-${var.cluster-name}"
  eks-sg-name         = "${local.env}-${var.eks-sg-name}"
  ec2-sg-name         = "${local.env}-${var.ec2-sg-name}"
  jenkins-ec2-sg-name = "${local.env}-${var.jenkins-ec2-sg-name}"
  ingress_value       = var.ingress_value
}
