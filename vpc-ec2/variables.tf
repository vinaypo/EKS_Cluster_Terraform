variable "env" {
}
# VPC and Subnets
variable "aws-region" {
  default = "us-east-1"
}
variable "cidr-block" {}
variable "vpc-name" {}
variable "igw-name" {}
variable "pub-subnet-count" {}
variable "pub-cidr-block" {
  type = list(string)
}

variable "pub-sub-name" {}
variable "pri-subnet-count" {}
variable "pri-cidr-block" {
  type = list(string)
}

variable "pri-sub-name" {}
variable "public-rt-name" {}
variable "ngw-eip-name" {}
variable "ngw-name" {}
variable "private-rt-name" {}
variable "cluster-name" {

}
variable "eks-sg-name" {}
variable "ec2-sg-name" {}

# EC2 Instance (for bastion host)
variable "ec2-instance-profile-name" {}
variable "ec2-role-name" {}
variable "ec2-policy-name" {}
variable "ec2-name" {}
variable "ami-id" {
  type = map(string)
  default = {
    "us-east-1" = "ami-0360c520857e3138f"
  }
}
variable "ec2-instance-type" {}
variable "key-name" {}
variable "user" {}
variable "connection_type" {}
variable "private_key" {}
variable "src" {}
variable "destination" {}
variable "commands" {}
