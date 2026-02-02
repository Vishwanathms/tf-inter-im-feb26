terraform {
  required_version = "~> 1.13.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.20.0"
    }
  }
}

provider "aws" {
  region = "us-west-1"

  default_tags {
    tags = {
      ManagedBy = "Terraform"
      Lab       = "lab6-import"
    }
  }
}
