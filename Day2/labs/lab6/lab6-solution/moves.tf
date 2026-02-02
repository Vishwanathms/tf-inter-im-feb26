# Step 3.2: Moved blocks for state reorganization
# Rename to moves.tf to use
# Can be deleted after successful apply (Step 3.5)

# Move S3 bucket to new address
moved {
  from = aws_s3_bucket.legacy_logs
  to   = aws_s3_bucket.logs
}

# Move IAM role to new address
moved {
  from = aws_iam_role.legacy_app
  to   = aws_iam_role.application
}
