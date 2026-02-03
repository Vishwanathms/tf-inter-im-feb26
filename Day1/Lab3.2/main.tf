terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# --- Default VPC + subnets ---
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_subnet" "details" {
  for_each = toset(data.aws_subnets.default.ids)
  id       = each.value
}

# Pick one default subnet (simple demo)
locals {
  #subnet_id = data.aws_subnets.default.ids[0]
  subnet_id = [
    for s in data.aws_subnet.details :
    s.id if s.availability_zone != "us-east-1e"
  ]
}

# --- Ubuntu 22.04 AMI (Canonical) ---
data "aws_ami" "ubuntu_2204" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# --- Security Groups ---
# Redis SG: allow 6379 ONLY from python-sg
resource "aws_security_group" "redis_sg" {
  name        = "${var.name_prefix}-redis-sg"
  description = "Redis SG"
  vpc_id      = data.aws_vpc.default.id

  # SSH (optional)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  # Redis from python SG only
  ingress {
    description     = "Redis from Python SG"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.python_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Python SG: allow HTTP (5000) from internet, SSH optional
resource "aws_security_group" "python_sg" {
  name        = "${var.name_prefix}-python-sg"
  description = "Python SG"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP Flask"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH (optional)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- EC2 #1: Redis ---
resource "aws_instance" "redis" {
  ami                         = data.aws_ami.ubuntu_2204.id
  instance_type               = var.instance_type
  subnet_id                   = local.subnet_id[0]
  vpc_security_group_ids      = [aws_security_group.redis_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  user_data = file("${path.module}/user_data/redis.sh")

  tags = {
    Name = "${var.name_prefix}-redis"
  }
}

# --- EC2 #2: Python app ---
resource "aws_instance" "python" {
  ami                         = data.aws_ami.ubuntu_2204.id
  instance_type               = var.instance_type
  subnet_id                   = local.subnet_id[0]
  vpc_security_group_ids      = [aws_security_group.python_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  # Inject Redis private IP into user_data via templatefile()
  user_data = templatefile("${path.module}/user_data/python.sh.tftpl", {
    redis_ip = aws_instance.redis.private_ip
  })

  # Ensures ordering (also implied by private_ip reference, but kept explicit)
  depends_on = [aws_instance.redis]

  tags = {
    Name = "${var.name_prefix}-python"
  }
}
