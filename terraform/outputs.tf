output "vpc_id" { value = aws_vpc.main.id }
output "alb_dns" { value = aws_lb.alb.dns_name }
output "ec2_public_ips" { value = [aws_instance.app1.public_ip, aws_instance.app2.public_ip] }
output "s3_bucket" { value = aws_s3_bucket.artifacts.bucket }
