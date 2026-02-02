#!/bin/bash
# Script to clean up all lab6 resources
# Use this if you need to start the lab over or if cleanup failed

set -e

# Check if PROJECT is set
if [ -z "$PROJECT" ]; then
    echo "Error: PROJECT environment variable not set"
    echo "Usage: export PROJECT=userX && ./cleanup-legacy-resources.sh"
    exit 1
fi

NAME_PREFIX="lab6-${PROJECT}"

echo "Cleaning up lab6 resources for project: $PROJECT"
echo ""

# Delete S3 bucket
echo "Deleting S3 bucket..."
aws s3 rb s3://${NAME_PREFIX}-logs-bucket --force 2>/dev/null || echo "Bucket already deleted or doesn't exist"

# Delete IAM role
echo "Deleting IAM role..."
aws iam delete-role --role-name ${NAME_PREFIX}-app-role 2>/dev/null || echo "IAM role already deleted or doesn't exist"

echo ""
echo "Cleanup complete!"
