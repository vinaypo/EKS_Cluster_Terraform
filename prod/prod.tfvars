env        = "prod"
aws-region = "us-east-1"

# vpc
cidr-block       = "192.168.0.0/16"
vpc-name         = "eks-vpc"
igw-name         = "eks-igw"
pub-subnet-count = "3"
pub-cidr-block   = ["192.168.1.0/24", "192.168.2.0/24", "192.168.3.0/24"]
pub-sub-name     = "eks-public-subnet"
pri-subnet-count = "3"
pri-cidr-block   = ["192.168.4.0/24", "192.168.5.0/24", "192.168.6.0/24"]
pri-sub-name     = "eks-private-subnet"
public-rt-name   = "eks-public-rt"
ngw-eip-name     = "eks-ngw-eip"
ngw-name         = "eks-ngw"
private-rt-name  = "eks-private-rt"
eks-sg-name      = "eks-sg"
ec2-sg-name      = "bastion-sg"

# Eks
cluster-name             = "eks-cluster"
is_eks_role_enabled      = true
is_eks_node_role_enabled = true
is_eks_cluster_enabled   = true
cluster-version          = "1.33"
endpoint-private-access  = true
endpoint-public-access   = false
addons = [
  {
    name    = "vpc-cni",
    version = "v1.20.0-eksbuild.1"
  },
  {
    name    = "coredns"
    version = "v1.12.2-eksbuild.4"
  },
  {
    name    = "kube-proxy"
    version = "v1.33.0-eksbuild.2"
  },
  {
    name    = "aws-ebs-csi-driver"
    version = "v1.46.0-eksbuild.1"
  }
]
desired_capacity_ondemand = "1"
desired_capacity_spot     = "1"
max_size_ondemand         = "3"
max_size_spot             = "5"
min_size_ondemand         = "1"
min_size_spot             = "1"
ondemand_instance_types   = ["t3.medium"]
spot_instance_types       = ["c5a.large", "c5a.xlarge", "m5a.large", "m5a.xlarge", "c5.large", "m5.large", "t3a.large", "t3a.xlarge", "t3a.medium"]


# Ec2 Instance (for bastion host)
ec2-instance-profile-name = "bastion-ec2-role"
ec2-role-name             = "bastion-ec2-role"
ec2-policy-name           = "bastion-ec2-policy"
ec2-name                  = "Jump_Server"
ami-id = {

  "us-east-1" = "ami-0360c520857e3138f"
  "us-east-2" = "ami-0ca4d5db4872d0c28"
}
ec2-instance-type = "t2.micro"
key-name          = "terraform"
user              = "ubuntu"
connection_type   = "ssh"
private_key       = "C:/Users/Vinay/Downloads/terraform.pem"
src               = "./prod/install.sh"
destination       = "/home/ubuntu/install.sh"
commands          = ["chmod +x /home/ubuntu/install.sh", "sudo bash /home/ubuntu/install.sh"]
