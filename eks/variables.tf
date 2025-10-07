#EKS 
variable "env" {}
variable "aws-region" {

}
variable "cluster-name" {}
variable "vpc-name" {}
variable "is_eks_role_enabled" {
  type = bool
}
variable "is_eks_node_role_enabled" {
  type = bool
}
variable "is_eks_cluster_enabled" {
  type = bool
}
variable "cluster-version" {}
variable "endpoint-private-access" {
  type = bool
}
variable "endpoint-public-access" {
  type = bool
}
variable "addons" {
  type = list(object({
    name    = string
    version = string
  }))
}
variable "desired_capacity_ondemand" {}
variable "desired_capacity_spot" {}
variable "max_size_ondemand" {}
variable "max_size_spot" {}
variable "min_size_ondemand" {}
variable "min_size_spot" {}
variable "ondemand_instance_types" {}
variable "spot_instance_types" {}
variable "eks-sg-name" {}

