# Organized resource structure - FINAL STATE after Part 4
# This file represents the final state after Part 4 (state rm)

# Storage resources
resource "aws_s3_bucket" "logs" {
  bucket = "${local.name_prefix}-logs-bucket"

  tags = {
    Name        = "${local.name_prefix}-logs-bucket"
    Environment = "production"
    Purpose     = "logs"
    Owner       = var.project
  }
}

# Note: IAM role removed from Terraform management in Part 4
# It still exists in AWS but is managed manually or by another config
