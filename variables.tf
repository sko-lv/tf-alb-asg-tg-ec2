variable "subnet_ids" {
  description = "The ID of the subnet where the ALB will be deployed"
  type        = list(string)
}

variable "vpc_id" {
  description = "The ID of the VPC where the resources will be deployed"
  type        = string
}

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

variable "dns_site_name" {
  description = "FQDN for site A-record"
  type        = string
}

variable "ssl_certificate_arn" {
  description = "ARN of SSL/TLS certificate"
  type        = string
}
