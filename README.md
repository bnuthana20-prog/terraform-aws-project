# Terraform AWS Project

Hands-on Infrastructure as Code project to provision AWS resources using Terraform.

## 📚 8-Hour Terraform Module - Completed
| Topic | What We Did |
| --- | --- |
| **Infrastructure as Code** | Learned IaC workflow: `init` → `plan` → `apply` → `destroy` |
| **Terraform Architecture** | Core → Provider → AWS API. Configured AWS Provider |
| **Providers** | Set up `hashicorp/aws` provider for ap-south-1 |
| **Resources** | Created VPC, Subnet, IGW, Route Table, SG, EC2 using Terraform |
| **Variables** | Used variables.tf + terraform.tfvars to remove hardcoded values |
| **Outputs + Locals** | Used outputs for Public IP and locals for reusable values |
| **AWS Project** | Built full VPC + EC2 stack. Fixed "Network is unreachable" error |
| **Revision** | Revised state file, fmt, validate, best practices |

## 🚀 Day 5 Project: VPC + EC2 + Nginx Deployment
**What this project does:**
1. Creates custom VPC with Public Subnet
2. Sets up Internet Gateway + Route Table for internet access  
3. Launches EC2 instance with Security Group for port 22 and 80
4. Installs Nginx automatically using `user_data`
5. Outputs Public IP

**Key Challenge Solved:** Fixed "Network is unreachable" by properly configuring IGW and Route Table Association

**Live Demo:** http://15.206.67.194
![Terraform Success](wa_image_1835007331189208291)

## 🛠️ How to Run
```bash
terraform init
terraform plan  
terraform apply
