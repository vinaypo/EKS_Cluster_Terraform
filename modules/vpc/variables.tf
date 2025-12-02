variable "cluster-name" {}
variable "cidr-block" {}
variable "vpc-name" {}
variable "env" {}
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
variable "eks-sg-name" {}
variable "ec2-sg-name" {}
variable "jenkins-ec2-sg-name" {}
variable "ingress_value" {
}
