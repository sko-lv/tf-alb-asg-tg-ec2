provider "aws" {
  region                   = "us-east-1"
  profile                  = "default"
  shared_credentials_files = ["~/.aws/credentials"]
}

# Configure Terraform S3 backend to use with DynamoDB locking for current environment
# s3 bucket and DynamoDB table should be created before.
# VARIABLES IS NOT ALLOWED HERE! 
terraform {
  backend "s3" {
    bucket         = "labs2024-terraform-state-bucket-12"
    key            = "lab2/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock-table"
    encrypt        = true
  }
}

data "aws_region" "current" {}
