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

# 2. EC2 Instance
resource "aws_instance" "web" {
  count         = 3  # <-- this makes 3 copies
  ami           = "ami-0f5ee92e2d63afc18" # Amazon Linux 2 in ap-south-1
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  # This runs on each server. count.index = 0, 1, 2
  user_data = <<-EOF
              #!/bin/bash
              yum install -y httpd
              systemctl start httpd
              echo "<h1>This is Server ${count.index + 1}</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "web-server-${count.index + 1}" # web-server-1, web-server-2, web-server-3
  }
}
output "all_public_ips" {
  value = aws_instance.web[*].public_ip  # [*] gets IPs from all 3 servers
}