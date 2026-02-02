output "s3_bucket_name" {
  description = "Name of the S3 bucket for state storage"
  value       = aws_s3_bucket.terraform_state.bucket
}
