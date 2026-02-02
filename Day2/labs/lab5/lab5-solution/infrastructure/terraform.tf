terraform {
  required_version = "~> 1.13.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.20.0"
    }
  }

  # Remote state configuration
  # IMPORTANT: Replace YOUR_STATE_BUCKET with your actual bucket name
  backend "s3" {
    bucket       = "YOUR_STATE_BUCKET"
    key          = "lab5/infrastructure/terraform.tfstate"
    region       = "us-west-1"
    encrypt      = true
    use_lockfile = true  # S3 native locking (Terraform 1.10+)
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      owner  = var.project
      Course = "Terraform-Intermediate"
      Lab    = "lab5"
      Layer  = "infrastructure"
    }
  }
}
