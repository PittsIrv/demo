terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "aws" {
  region = var.region
  profile = "terraformer"
}

data "aws_availability_zones" "available" {}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-2"
}

resource "aws_key_pair" "deployer" {
  key_name   = "terraform-demo-key"
  public_key = file("~/.ssh/terraform_demo.pub")
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "demo-vpc"
  }
}

# Public and Private Subnets in two AZs
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 4, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "public-${count.index}"
  }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 4, count.index + 2)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "private-${count.index}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "demo-igw" }
}

# EIP for NAT Gateway
resource "aws_eip" "nat" {
  vpc = true
}

# NAT Gateway in public subnet 0
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags          = { Name = "demo-nat" }
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "public-rt" }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = { Name = "private-rt" }
}

# Route Table Associations
resource "aws_route_table_association" "public_assoc" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_assoc" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Security Group
resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Allow HTTP, HTTPS, SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "web-sg" }
}

# EC2 Instance
resource "aws_instance" "app" {
    ami                         = data.aws_ami.amazon_linux.id
    instance_type               = "t2.micro"
    subnet_id                   = aws_subnet.public[0].id
    key_name                     = aws_key_pair.deployer.key_name
    vpc_security_group_ids      = [aws_security_group.web.id]
    associate_public_ip_address = true

  user_data = <<EOF
#!/bin/bash
yum update -y
amazon-linux-extras install -y docker
service docker start
usermod -aG docker ec2-user

# install Compose v2 plugin
mkdir -p /home/ec2-user/.docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-linux-$(uname -m) \
  -o /home/ec2-user/.docker/cli-plugins/docker-compose
chmod +x /home/ec2-user/.docker/cli-plugins/docker-compose

# clone and launch
yum install -y git
cd /home/ec2-user
rm -rf deploy-docker
git clone https://github.com/PittsIrv/demo.git deploy-docker
cd deploy-docker
docker-compose up -d
EOF

  tags = { Name = "demo-app-instance" }
}

# Outputs
output "instance_public_ip" {
  value       = aws_instance.app.public_ip
  description = "Public IP of the demo EC2 instance"
}
