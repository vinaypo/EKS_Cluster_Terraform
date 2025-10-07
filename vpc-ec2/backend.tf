terraform {
  backend "s3" {
    bucket = "eks-cluster-terraform-state-8213"
    key    = "vpc/terraform.tfstate"
    region = "us-east-1"
    #dynamodb_table = "Lock-Files"
    use_lockfile = true
    encrypt      = true
  }
}
