provider "aws" {
  region                   = "us-east-1"
  profile                  = "default"
  shared_credentials_files = ["~/.aws/credentials"]
}

# Configure Terraform backend to use S3 with DynamoDB locking for dev environment
terraform {
  backend "s3" {
    bucket         = "labs2024-terraform-state-bucket-12"
    key            = "lab2/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock-table"
    encrypt        = true
  }
}
