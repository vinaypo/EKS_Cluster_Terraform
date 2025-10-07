output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnet_ids" {
  value = aws_subnet.public-subnet[*].id
}
output "private_subnet_ids" {
  value = aws_subnet.private-subnet[*].id
}
output "eks_sg_id" {
  value = aws_security_group.eks-sg.id
}

output "ec2_sg_id" {
  value = aws_security_group.ec2-sg.id

}
