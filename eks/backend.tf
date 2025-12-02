terraform {
  backend "s3" {
    bucket = "eks-cluster-terraform-state-4764"
    key    = "eks/terraform.tfstate"
    region = "us-east-1"
    #dynamodb_table = "Lock-Files"
    use_lockfile = true
    encrypt      = true
  }
}
