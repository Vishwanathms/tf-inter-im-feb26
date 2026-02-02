# Lab 6: Import and State Surgery

## Lab Overview

In this lab, you'll learn how to bring existing AWS resources under Terraform management using `import` blocks and perform state surgery operations using `moved` blocks and `terraform state rm`. These are essential skills for adopting Terraform in environments with existing infrastructure.

**Duration:** 35-40 minutes

## Learning Objectives

By the end of this lab, you will be able to:
- Import existing AWS resources into Terraform state using `import` blocks
- Generate configuration for imported resources
- Use `moved` blocks to rename and reorganize resources
- Use `removed` blocks to remove resources from state
- Understand when and why to use each state operation

## Scenario

Your organization has several resources that were created manually in the AWS Console:
- An S3 bucket for logs
- An IAM role for an application

Your task is to bring these resources under Terraform management without recreating them, then reorganize the state structure for better maintainability.

---

## Part 1: Setup and Create "Existing" Resources

First, we'll create resources using AWS CLI to simulate "existing" infrastructure that needs to be imported.

### Step 1.1: Create Directory Structure

```bash
mkdir -p ~/lab6-im
cd ~/lab6-im
```

### Step 1.2: Set Your Variables

```bash
# Replace X with your user number
export PROJECT="userX"
export NAME_PREFIX="lab6-${PROJECT}"
export AWS_REGION="us-west-1"
```

### Step 1.3: Create "Existing" Resources via AWS CLI

These commands create resources as if they were created manually (outside Terraform):

```bash
# Create an S3 bucket for logs
aws s3api create-bucket \
  --bucket ${NAME_PREFIX}-logs-bucket \
  --region ${AWS_REGION} \
  --create-bucket-configuration LocationConstraint=${AWS_REGION}

# Add tags to the bucket
aws s3api put-bucket-tagging \
  --bucket ${NAME_PREFIX}-logs-bucket \
  --tagging 'TagSet=[{Key=Environment,Value=production},{Key=Purpose,Value=logs}]'

echo "Created S3 bucket: ${NAME_PREFIX}-logs-bucket"

# Create an IAM role for the application
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

echo "Created IAM Role: ${NAME_PREFIX}-app-role"
```

---

## Part 2: Import Resources Using Import Blocks

The `import` block is the modern, declarative approach for bringing existing resources under Terraform management. It integrates with the standard plan/apply workflow.

### Why Use Import Blocks?

| Feature | Description |
|---------|-------------|
| Preview changes | Shows imports in `terraform plan` before modifying state |
| CI/CD friendly | Declarative and automatable |
| Generate config | Built-in with `-generate-config-out` |
| Collaboration | Version controlled and reviewable in PRs |

### Step 2.1: Create Initial Terraform Configuration

Copy `terraform.tf` from the solution:

```bash
cp ~/intermediate/day2/labs/lab6/lab6-solution/terraform.tf .
```

Review the contents:

```hcl
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
```

### Step 2.2: Write Resource Configurations

Copy `variables.tf` from the solution:

```bash
cp ~/intermediate/day2/labs/lab6/lab6-solution/variables.tf .
```

Review the contents:

```hcl
variable "project" {
  description = "Use userX format, replace X with your user number. Uncomment default to avoid prompt."
  type        = string
  # default   = "userX"
}

locals {
  name_prefix = "lab6-${var.project}"
}
```

> **Action Required:** Edit `variables.tf` to set your user number:
> 1. Open the file and find the commented line `# default   = "userX"`
> 2. Uncomment it by removing the `#` at the beginning of the line
> 3. Replace `X` with your assigned user number (e.g., `default = "user1"`)

Copy `legacy_resources.tf` from the solution:

```bash
cp ~/intermediate/day2/labs/lab6/lab6-solution/step2.2-legacy_resources.tf.example legacy_resources.tf
```

Review the resource blocks that match the existing resources:

```hcl
# S3 Bucket - will be imported
resource "aws_s3_bucket" "legacy_logs" {
  bucket = "${local.name_prefix}-logs-bucket"

  tags = {
    Name        = "${local.name_prefix}-logs-bucket"
    Environment = "production"
    Purpose     = "logs"
    Owner       = var.project
  }
}

# IAM Role - will be imported
resource "aws_iam_role" "legacy_app" {
  name = "${local.name_prefix}-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "${local.name_prefix}-app-role"
    Environment = "production"
    Purpose     = "application"
    Owner       = var.project
  }
}
```

### Step 2.3: Create Import Blocks

Copy `imports.tf` from the solution:

```bash
cp ~/intermediate/day2/labs/lab6/lab6-solution/step2.3-imports.tf.example imports.tf
```

Review the import blocks for each resource:

```hcl
# Import block for S3 bucket
import {
  to = aws_s3_bucket.legacy_logs
  id = "${local.name_prefix}-logs-bucket"
}

# Import block for IAM role
import {
  to = aws_iam_role.legacy_app
  id = "${local.name_prefix}-app-role"
}
```

### Step 2.4: Initialize and Preview Import

```bash
# Initialize Terraform
terraform init

# Preview what will be imported
terraform plan
```

**Expected Output:** The plan should show 2 resources to import (S3 bucket and IAM role).

### Step 2.5: Apply Import

```bash
# Apply to import resources
terraform apply
```

Type `yes` when prompted.

### Step 2.6: Clean Up Import Blocks

After successful import, remove the `imports.tf` file - it's no longer needed:

```bash
rm imports.tf
```

### Step 2.7: Verify State

```bash
# Check the state
terraform state list

# Verify no changes needed
terraform plan
```

**Expected Output:** "No changes" - all resources are now managed by Terraform.

---

## Part 3: Reorganize State Using Moved Blocks

The `moved` block is the modern, declarative approach for reorganizing resources in state. It integrates with the standard plan/apply workflow.

### Why Use Moved Blocks?

| Feature | Description |
|---------|-------------|
| Preview changes | Shows moves in `terraform plan` before modifying state |
| CI/CD friendly | Declarative and automatable |
| Collaboration | Version controlled and reviewable in PRs |
| Rollback | Part of normal apply workflow |

### Step 3.1: Create New Resource Structure

We want to reorganize resources with better naming. Copy `organized_resources.tf` from the solution:

```bash
cp ~/intermediate/day2/labs/lab6/lab6-solution/step3.1-organized_resources.tf.example organized_resources.tf
```

Review the reorganized structure:

```hcl
# Reorganized structure with better naming

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

# IAM resources
resource "aws_iam_role" "application" {
  name = "${local.name_prefix}-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "${local.name_prefix}-app-role"
    Environment = "production"
    Purpose     = "application"
    Owner       = var.project
  }
}
```

### Step 3.2: Create Moved Blocks

Copy `moves.tf` from the solution:

```bash
cp ~/intermediate/day2/labs/lab6/lab6-solution/step3.2-moves.tf.example moves.tf
```

Review the moved blocks:

```hcl
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
```

### Step 3.3: Remove Old Configuration

Delete the `legacy_resources.tf` file:

```bash
rm legacy_resources.tf
```

### Step 3.4: Preview and Apply Moves

```bash
# Plan shows what will be moved
terraform plan

# Apply performs the state moves
terraform apply
```

**Expected Output:** The plan should show resources being moved, with no actual infrastructure changes.

### Step 3.5: Clean Up Moved Blocks (Optional)

After successful apply, you can optionally remove the `moves.tf` file. Keeping it doesn't cause issues and documents the refactoring history.

### Step 3.6: Verify State

```bash
# List current state
terraform state list

# Verify no changes needed
terraform plan
```

**Expected Output:** "No changes" - resources have been reorganized in state without affecting infrastructure.

---

## Part 4: Removing Resources from State Using Removed Blocks

Sometimes you need to remove a resource from Terraform management without destroying it. The `removed` block (introduced in Terraform 1.7) is the modern, declarative approach for this.

### Why Use Removed Blocks?

The `removed` block integrates with the plan/apply workflow, just like `import` and `moved` blocks:

- Preview the removal in `terraform plan` before it happens
- Version controlled and reviewable in PRs
- CI/CD friendly and automatable

### Step 4.1: Understanding State Removal

Use `removed` blocks when:
- Transferring resource ownership to another team/config
- Removing a resource from Terraform management (manual management)
- The resource should continue to exist in AWS

### Step 4.2: Create a Removed Block

Let's remove the IAM role from Terraform management (pretend another team will manage it).

Copy `removed.tf` from the solution:

```bash
cp ~/intermediate/day2/labs/lab6/lab6-solution/step4.2-removed.tf.example removed.tf
```

Review the removed block:

```hcl
# Remove IAM role from Terraform management
# The role will continue to exist in AWS
removed {
  from = aws_iam_role.application

  lifecycle {
    destroy = false  # Keep the resource in AWS
  }
}
```

**Important:** The `lifecycle { destroy = false }` is required to prevent Terraform from deleting the actual AWS resource. Without it, Terraform would destroy the resource.

### Step 4.3: Remove the Resource Block from Configuration

Remove the IAM role resource block from `organized_resources.tf`. Copy the updated version from the solution:

```bash
cp ~/intermediate/day2/labs/lab6/lab6-solution/step4.3-organized_resources.tf.example organized_resources.tf
```

The file should now contain only:

```hcl
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
```

### Step 4.4: Preview and Apply

```bash
# Preview the removal
terraform plan

# Apply the removal
terraform apply
```

**Expected Output:** The plan will show the IAM role being removed from state. The resource continues to exist in AWS.

### Step 4.5: Clean Up Removed Block

After successful apply, delete the `removed.tf` file:

```bash
rm removed.tf
```

### Step 4.6: Verify

```bash
# Check state - IAM role should be gone
terraform state list

# Plan should show no changes
terraform plan
```

---

## Part 5: Cleanup

### Step 5.1: Destroy Terraform-Managed Resources

```bash
# Destroy resources still managed by Terraform (just the S3 bucket now)
terraform destroy
```

Type `yes` when prompted.

### Step 5.2: Clean Up Manually-Managed Resources

The IAM role we removed from state still exists and must be deleted manually:

```bash
# Delete the IAM role (not managed by Terraform anymore)
aws iam delete-role --role-name ${NAME_PREFIX}-app-role
```

---

## Key Takeaways

1. **Import with `import` blocks** - The modern, declarative approach:
   - Integrates with plan/apply workflow
   - Preview imports before they happen
   - CI/CD friendly and version controlled
   - Use `-generate-config-out` to auto-generate configuration

2. **Reorganize with `moved` blocks** - The modern, declarative approach:
   - Integrates with plan/apply workflow
   - Preview moves before they happen
   - CI/CD friendly and version controlled
   - Documents refactoring history

3. **Remove with `removed` blocks** - The modern, declarative approach:
   - Integrates with plan/apply workflow
   - Preview removals before they happen
   - Use `lifecycle { destroy = false }` to keep the resource in AWS
   - CI/CD friendly and version controlled

4. **Best Practices:**
   - Always backup state before surgery: `terraform state pull > backup.tfstate`
   - Test in non-production first
   - Document all state operations
   - Use version control for configuration changes

---

## Troubleshooting

### Import Fails with "Resource Not Found"
- Verify the resource exists with AWS CLI
- Check the resource ID/ARN format is correct
- Ensure you have appropriate AWS permissions

### Plan Shows Changes After Import
- Your configuration doesn't match actual resource
- Read the plan output to identify differences
- Update configuration to match reality

### Moved Block Errors
- Check source address exists: `terraform state list`
- Ensure destination resource block exists in configuration
- Both old and new resource blocks must exist during the move

### Removed Block Errors
- "Removed resource still exists": You cannot use a `removed` block while the resource block is still in your configuration - delete the resource block first
- Verify you have `lifecycle { destroy = false }` if you want to keep the resource in AWS

---

## Documentation Links

- [Import Block](https://developer.hashicorp.com/terraform/language/import)
- [Moved Block](https://developer.hashicorp.com/terraform/language/moved)
- [Removed Block](https://developer.hashicorp.com/terraform/language/state/remove)

---

## Summary

In this lab, you learned how to:
- Import existing AWS resources into Terraform using `import` blocks
- Handle configuration drift after import
- Reorganize state with `moved` blocks
- Remove resources from management with `removed` blocks
- Properly clean up both Terraform-managed and manually-managed resources

These skills are essential for adopting Terraform in brownfield environments and maintaining clean, organized infrastructure code.
