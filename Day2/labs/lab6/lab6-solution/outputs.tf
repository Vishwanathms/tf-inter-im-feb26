# Outputs for organized resources (Part 3 state)
# Note: IAM role outputs are commented out for Part 4 (state rm demo)
# Uncomment if keeping IAM role in Terraform management

output "logs_bucket_name" {
  description = "Name of the logs S3 bucket"
  value       = aws_s3_bucket.logs.id
}

output "logs_bucket_arn" {
  description = "ARN of the logs S3 bucket"
  value       = aws_s3_bucket.logs.arn
}

# output "application_role_arn" {
#   description = "ARN of the application IAM role"
#   value       = aws_iam_role.application.arn
# }

# output "application_role_name" {
#   description = "Name of the application IAM role"
#   value       = aws_iam_role.application.name
# }
