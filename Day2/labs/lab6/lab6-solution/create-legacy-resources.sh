#!/bin/bash
# Script to create "existing" resources for import exercise
# Run this before starting the Terraform import exercise

set -e

# Check if PROJECT is set
if [ -z "$PROJECT" ]; then
    echo "Error: PROJECT environment variable not set"
    echo "Usage: export PROJECT=userX && ./create-legacy-resources.sh"
    exit 1
fi

NAME_PREFIX="lab6-${PROJECT}"
AWS_REGION="${AWS_REGION:-us-west-1}"

echo "Creating lab6 resources for project: $PROJECT"
echo "Region: $AWS_REGION"
echo ""

# Create S3 bucket
echo "Creating S3 bucket..."
aws s3api create-bucket \
    --bucket ${NAME_PREFIX}-logs-bucket \
    --region ${AWS_REGION} \
    --create-bucket-configuration LocationConstraint=${AWS_REGION}

aws s3api put-bucket-tagging \
    --bucket ${NAME_PREFIX}-logs-bucket \
    --tagging 'TagSet=[{Key=Environment,Value=production},{Key=Purpose,Value=logs}]'

echo "S3 bucket created: ${NAME_PREFIX}-logs-bucket"

# Create IAM role
echo ""
echo "Creating IAM role..."
aws iam create-role \
    --role-name ${NAME_PREFIX}-app-role \
    --assume-role-policy-document '{
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Principal": {"Service": "ec2.amazonaws.com"},
            "Action": "sts:AssumeRole"
        }]
    }' \
    --tags Key=Environment,Value=production Key=Purpose,Value=application

echo "IAM role created: ${NAME_PREFIX}-app-role"

echo ""
echo "All lab6 resources created!"
echo ""
echo "Resources created:"
echo "  - S3 Bucket: ${NAME_PREFIX}-logs-bucket"
echo "  - IAM Role: ${NAME_PREFIX}-app-role"
