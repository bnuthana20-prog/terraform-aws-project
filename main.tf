locals {
  project_name = "web-app"
  instance_count = 3
  common_tags = {
    Project = local.project_name
    Owner   = "Nuthana"
  }
}
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# 1. Security Group - Allow SSH + HTTP
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH and HTTP"

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# IAM Role so EC2 can pull from ECR
resource "aws_iam_role" "ec2_role" {
  name = "ec2-ecr-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# EC2 that runs your Docker container
resource "aws_instance" "app" {
  count                  = 3
  ami                    = "ami-0f58b3f70d7d06c7a" # Ubuntu 22.04 ap-south-1
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public[count.index % 2].id
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids = [aws_security_group.ec2.id]

  user_data = <<-EOF
  #!/bin/bash
  apt update -y
  apt install docker.io awscli -y
  systemctl start docker
  systemctl enable docker

  aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin 717491933397.dkr.ecr.ap-south-1.amazonaws.com
  docker run -d -p 80:80 --name webapp 717491933397.dkr.ecr.ap-south-1.amazonaws.com/my-webapp:latest
  EOF

  tags = { Name = "docker-ec2-${count.index + 1}" }
}
output "all_ec2_ips" {
  value = aws_instance.app[*].public_ip  # [*] gets IPs from all 3 servers
}
output "alb_dns_name" {
  value = aws_lb.main.dns_name
}