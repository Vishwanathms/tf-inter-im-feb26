# Terraform and provider version requirements
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.20.0"
    }
  }
  required_version = "~> 1.13.5"
}

# AWS Provider configuration
provider "aws" {
  region = "us-west-1"

  default_tags {
    tags = {
      owner = var.project
    }
  }
}


