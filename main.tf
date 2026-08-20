locals {
  project_name   = "web-app"
  instance_count = 3
  vpc_id         = "vpc-0481387c8b28dd203" # <-- YOUR DEFAULT VPC WHERE EC2S ARE
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

# Get default VPC subnets
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }
}

# 1. Security Group for EC2 - Allow 3000 for ALB + SSH
resource "aws_security_group" "ec2" {
  name        = "ec2-sg"
  description = "Allow 3000 from ALB"
  vpc_id      = local.vpc_id

  ingress {
  description     = "App port from ALB"
  from_port       = 3000
  to_port         = 3000
  protocol        = "tcp"
  security_groups = [aws_security_group.alb.id]  
}

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
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

# 2. Security Group for ALB - Allow 80
resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Allow HTTP"
  vpc_id      = local.vpc_id

  ingress {
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

# 3. IAM Role so EC2 can pull from ECR
resource "aws_iam_role" "ec2_role" {
  name = "ec2-ecr-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
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

# 4. ALB
resource "aws_lb" "main" {
  name               = "webapp-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.public.ids
}

# 5. Target Group - PORT 3000
resource "aws_lb_target_group" "app" {
  name        = "webapp-tg-v2"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "instance"

  health_check {
    path                = "/"
    port                = "3000"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
  }
lifecycle {
  create_before_destroy = true
  }
}

# 6. Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# 7. EC2 that runs your Docker container on port 3000
resource "aws_instance" "app" {
  count         = 3
  ami           = "ami-0f58b3f70d7d06c7a" 
  instance_type = "t3.micro"
  subnet_id     = data.aws_subnets.public.ids[count.index % length(data.aws_subnets.public.ids)]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids = [aws_security_group.ec2.id]

 user_data = <<-EOF
            #!/bin/bash
            apt update -y
            apt install docker.io awscli -y
            systemctl start docker
            systemctl enable docker
            
            # Wait for docker to be ready
            until systemctl is-active --quiet docker; do sleep 2; done
            
            sleep 15
            aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin 717491933397.dkr.ecr.ap-south-1.amazonaws.com
            docker run -d -p 80:3000 --name webapp --restart always 717491933397.dkr.ecr.ap-south-1.amazonaws.com/my-webapp:latest
            EOF

  tags = merge(local.common_tags, { Name = "docker-ec2-${count.index + 1}" })
} # <- CLOSE aws_instance HERE

# 7.1 Attach all instances to Target Group - OUTSIDE aws_instance
resource "aws_lb_target_group_attachment" "app_attach" {
  count            = length(local_instance.app)
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = local_instance.ids[count.index]
  port             = 3000
}

# 8. Outputs
output "all_ec2_ids" {
  value = aws_instance.app[*].id  # Added this to match instance id
}

output "all_ec2_ips" {
  value = aws_instance.app[*].public_ip
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}
