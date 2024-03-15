variable "aws_region" {
  description = "The AWS region where the resources will be provisioned"
  type        = string
}

variable "security_group_ids" {
  description = "The ID of the security group for the ALB"
  type        = list(string)
}

variable "subnet_ids" {
  description = "The ID of the subnet where the ALB will be deployed"
  type        = list(string)
}

variable "vpc_id" {
  description = "The ID of the VPC where the resources will be deployed"
  type        = string
}

# variable "az1" {
#   description = "The Availability Zone 1 for the Auto Scaling Group"
#   type        = string
# }

# variable "az2" {
#   description = "The Availability Zone 2 for the Auto Scaling Group"
#   type        = string
# }

variable "ami_id" {
  description = "The ID of the AMI for the instances launched by the Auto Scaling Group"
  type        = string
}

variable "ssh_key_name" {
  description = "SSH Key Pair namr for EC2 instance"
  type        = string
}

variable "dns_hosted_zone_id" {
  description = "The ID of the hosted zone in Route 53 where the A-record will be created"
  type        = string
}
