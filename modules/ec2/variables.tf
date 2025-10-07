# IAM Role and Policy for EC2 Instances
variable "ec2-instance-profile-name" {}
variable "ec2-role-name" {}
variable "ec2-policy-name" {}

# EC2 Instance (for bastion host)
variable "region" {}
variable "env" {}
variable "ec2-name" {}
variable "ami-id" {
  type = map(string)
}
variable "ec2-instance-type" {}
variable "key-name" {}
variable "public-subnet_id" {}
variable "ec2-sg-id" {}
variable "user" {}
variable "connection_type" {}
variable "private_key" {}
variable "src" {}
variable "destination" {}
variable "commands" {}

