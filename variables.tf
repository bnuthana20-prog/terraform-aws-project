variable "aws_region" { 
  type    = string 
  default = "ap-south-1" 
}

variable "instance_type" { 
  type    = string 
  default = "t3.micro" 
}

variable "key_name" { 
  type = string 
}

variable "ami_id" { 
  type    = string 
  default = "ami-0f58b1af5f7a59667" 
}

variable "project_name" { 
  type    = string 
  default = "MyFirstTerraformEC2" 
}
