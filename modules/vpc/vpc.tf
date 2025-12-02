data "aws_availability_zones" "az" {
  state = "available"
}

locals {
  cluster-name = var.cluster-name
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr-block
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc-name
    env  = var.env
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name                                          = var.igw-name
    env                                           = var.env
    "kubernetes.io/cluster/${local.cluster-name}" = "owned"
  }
  depends_on = [aws_vpc.vpc]
}

resource "aws_subnet" "public-subnet" {
  count                   = var.env == "prod" ? var.pub-subnet-count : var.env == "test" ? 2 : 1 # count is generally used for creating multiple resources in one block
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = element(var.pub-cidr-block, count.index)
  availability_zone       = element(data.aws_availability_zones.az.names, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name                                          = "${var.pub-sub-name}-${count.index + 1}"
    Env                                           = var.env
    "kubernetes.io/cluster/${local.cluster-name}" = "owned"
    "kubernetes.io/role/elb"                      = "1"
  }
  depends_on = [aws_vpc.vpc]
}

resource "aws_subnet" "private-subnet" {
  count                   = var.env == "prod" ? var.pri-subnet-count : var.env == "test" ? 2 : 1 # count is generally used for creating multiple resources in one block
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = element(var.pri-cidr-block, count.index)
  availability_zone       = element(data.aws_availability_zones.az.names, count.index)
  map_public_ip_on_launch = false

  tags = {
    Name                                          = "${var.pri-sub-name}-${count.index + 1}"
    Env                                           = var.env
    "kubernetes.io/cluster/${local.cluster-name}" = "owned"
    "kubernetes.io/role/internal-elb"             = "1"
  }
  depends_on = [aws_vpc.vpc]

}

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = var.public-rt-name
    env  = var.env
  }
  depends_on = [aws_vpc.vpc]
}

resource "aws_route_table_association" "pub-rt-ass" {
  count          = var.env == "prod" ? var.pub-subnet-count : var.env == "test" ? 2 : 1
  subnet_id      = aws_subnet.public-subnet[count.index].id
  route_table_id = aws_route_table.public-rt.id

  depends_on = [aws_vpc.vpc, aws_subnet.public-subnet]
}

resource "aws_eip" "ngw-eip" {
  count  = var.env == "prod" ? 2 : 1
  domain = "vpc"

  tags = {
    Name = var.ngw-eip-name
    env  = var.env
  }
  depends_on = [aws_vpc.vpc]

}

resource "aws_nat_gateway" "ngw" {
  count         = var.env == "prod" ? 2 : 1
  allocation_id = aws_eip.ngw-eip[count.index].id
  subnet_id     = aws_subnet.public-subnet[count.index].id

  tags = {
    Name = "${var.ngw-name}-${count.index + 1}"
    env  = var.env
  }
  depends_on = [aws_vpc.vpc, aws_eip.ngw-eip]
}

resource "aws_route_table" "private-rt" {
  count  = var.env == "prod" ? 2 : 1
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw[count.index].id
  }

  tags = {
    Name = "${var.private-rt-name}-${count.index + 1}"
    env  = var.env
  }
  depends_on = [aws_vpc.vpc]

}

resource "aws_route_table_association" "pri-rt-ass" {
  count          = var.env == "prod" ? var.pri-subnet-count : var.env == "test" ? 2 : 1
  subnet_id      = aws_subnet.private-subnet[count.index].id
  route_table_id = aws_route_table.private-rt[count.index % length(aws_route_table.private-rt)].id

  depends_on = [aws_vpc.vpc, aws_subnet.private-subnet]

}

resource "aws_security_group" "eks-sg" { # EKS Security Group
  name        = var.eks-sg-name
  description = "EKS Security Group"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2-sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = var.eks-sg-name
    env  = var.env
  }
}

resource "aws_security_group" "ec2-sg" {
  name        = var.ec2-sg-name
  description = "Allow 443 from Jump Server only"

  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] // It should be specific IP range
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.ec2-sg-name
    env  = var.env
  }
}
resource "aws_security_group" "jenkins-ec2-sg" {
  name        = var.jenkins-ec2-sg-name
  description = "Allowing Jenkins, Sonarqube"
  vpc_id      = aws_vpc.vpc.id

  dynamic "ingress" {
    for_each = var.ingress_value
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = var.jenkins-ec2-sg-name
    env  = var.env
  }
}
