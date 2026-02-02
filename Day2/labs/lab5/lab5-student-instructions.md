# Lab 5: Layered Architecture

## Split Infrastructure into Layers with Cross-Layer Data Sharing

---

## Objective

Learn to split Terraform configurations into separate layers (infrastructure and application) with independent state files, and share data between them using `terraform_remote_state`. This pattern enables team collaboration, reduces blast radius, and improves deployment flexibility.

---

## Time Estimate

**50-60 minutes**

---

## What You'll Learn

- Designing layered Terraform architectures
- Configuring separate S3 backends for each layer
- Using `terraform_remote_state` data source for cross-layer communication
- Managing deployment dependencies between layers
- Outputs as the interface between layers

---

## High-Level Instructions

1. Create the directory structure for all layers

**Part A: S3 Backend**
2. Set up S3 state bucket using backend-setup

**Part B: Infrastructure Layer**
3. Configure infrastructure layer (subnet, security group)
4. Deploy infrastructure layer with outputs

**Part C: Application Layer**
5. Configure application layer with `terraform_remote_state`
6. Deploy application layer using infrastructure outputs
7. Demonstrate update flow between layers

**Cleanup**
8. Clean up (in reverse order)

---

## Detailed Instructions

### Step 1: Create Directory Structure

```bash
cd ~
mkdir -p lab5-backend-setup-im
mkdir -p lab5-im/{infrastructure,application}
```

Your structure:
```
~/lab5-backend-setup-im/     (backend bucket - separate from lab5-im)
    terraform.tf
    main.tf
    variables.tf
    outputs.tf

~/lab5-im/infrastructure/
    terraform.tf
    main.tf
    variables.tf
    outputs.tf

~/lab5-im/application/
    terraform.tf
    main.tf
    data.tf
    variables.tf
    outputs.tf
```

---

## Part A: Create S3 Backend Bucket

Before creating the layered architecture, you need an S3 bucket to store Terraform state files.

### Step 2: Copy Backend Setup Files

Copy the provided backend-setup configuration:

```bash
cp -r ~/im/day2/labs/lab5-backend-setup-im/* ~/lab5-backend-setup-im/
cd ~/lab5-backend-setup-im
```

### Step 3: Update Variables

**Edit `lab5-backend-setup-im/variables.tf`:**

After copying, the file contains:

```hcl
variable "project" {
  description = "Use userX format, replace X with your user number. Uncomment default to avoid prompt."
  type        = string
  # default     = "userX"
}
```

> **Action Required:** Edit `variables.tf` to uncomment the `default` line for the `project` variable and replace `X` with your assigned user number. To uncomment, remove the `#` at the beginning of the line (e.g., change `# default = "userX"` to `default = "user3"` if you are user 3).

### Step 4: Create the S3 Bucket

```bash
cd ~/lab5-backend-setup-im

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Create the bucket
terraform apply
```

**Note the output:** The bucket name will be `boa-terraform-state-im-userX` (where X is your user number). You'll use this bucket name in the following steps.

```bash
# Verify the bucket name
terraform output s3_bucket_name
```

---

## Part B: Infrastructure Layer

### Step 5: Create Infrastructure terraform.tf

**Copy `terraform.tf` from the solution directory:**

```bash
cp ~/intermediate/day2/labs/lab5/lab5-solution/infrastructure/terraform.tf ~/lab5-im/infrastructure/
```

After copying, edit the file to update the bucket name. The file contains:

```hcl
terraform {
  required_version = "~> 1.13.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.20.0"
    }
  }

  # Remote state configuration
  # Use the bucket created in Part A: boa-terraform-state-im-userX
  backend "s3" {
    bucket       = "boa-terraform-state-im-userX"  # Replace userX with your user number
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
```

**Important:** Replace `userX` with your user number (e.g., `boa-terraform-state-im-user1`).

---

### Step 6: Create Infrastructure Variables

**Copy `variables.tf` from the solution directory:**

```bash
cp ~/intermediate/day2/labs/lab5/lab5-solution/infrastructure/variables.tf ~/lab5-im/infrastructure/
```

After copying, the file contains:

```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-1"
}

variable "project" {
  description = "Use userX format, replace X with your user number. Uncomment default to avoid prompt."
  type        = string
  # default     = "userX"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for subnet in default VPC"
  type        = string
  default     = "172.31.96.0/20"
}
```

> **Action Required:** Edit `variables.tf` to uncomment the `default` line for the `project` variable and replace `X` with your assigned user number. To uncomment, remove the `#` at the beginning of the line (e.g., change `# default = "userX"` to `default = "user3"` if you are user 3).

---

### Step 7: Create Infrastructure Main Configuration

**Copy `main.tf` from the solution directory:**

```bash
cp ~/intermediate/day2/labs/lab5/lab5-solution/infrastructure/main.tf ~/lab5-im/infrastructure/
```

The file contains:

```hcl
# Local values for consistent naming
locals {
  name_prefix = "lab5-${var.project}-${var.environment}"
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Create a subnet in the default VPC for our application
resource "aws_subnet" "app" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = var.vpc_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-app-subnet"
  }
}

# Security group for web servers
resource "aws_security_group" "web_sg" {
  name        = "${local.name_prefix}-web-sg"
  description = "Security group for web servers"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "${local.name_prefix}-web-sg"
  }
}

# Security group rule - HTTP ingress (standalone resource - best practice)
resource "aws_vpc_security_group_ingress_rule" "web_http" {
  security_group_id = aws_security_group.web_sg.id
  description       = "HTTP from anywhere"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "${local.name_prefix}-web-http"
  }
}

# Security group rule - egress (standalone resource - best practice)
resource "aws_vpc_security_group_egress_rule" "web_all" {
  security_group_id = aws_security_group.web_sg.id
  description       = "Allow all outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "${local.name_prefix}-web-egress"
  }
}
```

---

### Step 8: Create Infrastructure Outputs

**Copy `outputs.tf` from the solution directory:**

```bash
cp ~/intermediate/day2/labs/lab5/lab5-solution/infrastructure/outputs.tf ~/lab5-im/infrastructure/
```

These outputs are the **interface** that the application layer will consume.

```hcl
# These outputs will be consumed by the application layer
# via terraform_remote_state
# Key concept: Outputs serve as the interface for cross-layer communication

output "subnet_id" {
  description = "Application subnet ID"
  value       = aws_subnet.app.id
}

output "security_group_id" {
  description = "Web security group ID"
  value       = aws_security_group.web_sg.id
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}
```

---

### Step 9: Deploy Infrastructure Layer

```bash
cd ~/lab5-im/infrastructure

# Initialize with backend
terraform init

# Plan
terraform plan

# Apply
terraform apply
```

**Verify the outputs:**
```bash
terraform output
```

You should see all the outputs that the application layer will use.

---

## Part C: Application Layer

### Step 10: Create Application terraform.tf

**Copy `terraform.tf` from the solution directory:**

```bash
cp ~/intermediate/day2/labs/lab5/lab5-solution/application/terraform.tf ~/lab5-im/application/
```

After copying, edit the file to update the bucket name. The file contains:

```hcl
terraform {
  required_version = "~> 1.13.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.20.0"
    }
  }

  # Remote state - DIFFERENT key than infrastructure
  # Use the same bucket created in Part 0
  backend "s3" {
    bucket       = "boa-terraform-state-im-userX"  # Replace userX with your user number
    key          = "lab5/application/terraform.tfstate"
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
      Layer  = "application"
    }
  }
}
```

---

### Step 11: Create Application Data Sources

**Copy `data.tf` from the solution directory:**

```bash
cp ~/intermediate/day2/labs/lab5/lab5-solution/application/data.tf ~/lab5-im/application/
```

This is where we read the infrastructure layer's outputs. After copying, edit the file to update the bucket name.

```hcl
# Read infrastructure layer state
# This is how the application layer gets values from infrastructure
# Key concept: terraform_remote_state reads outputs from another state file
data "terraform_remote_state" "infrastructure" {
  backend = "s3"

  config = {
    bucket = "boa-terraform-state-im-userX"  # Replace userX with your user number
    key    = "lab5/infrastructure/terraform.tfstate"
    region = var.aws_region
  }
}

# Get the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
```

**Important:** Replace `userX` with your user number (e.g., `boa-terraform-state-im-user1`).

---

### Step 12: Create Application Variables

**Copy `variables.tf` from the solution directory:**

```bash
cp ~/intermediate/day2/labs/lab5/lab5-solution/application/variables.tf ~/lab5-im/application/
```

After copying, the file contains:

```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-1"
}

variable "project" {
  description = "Use userX format, replace X with your user number. Uncomment default to avoid prompt."
  type        = string
  # default     = "userX"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.nano"
}
```

> **Action Required:** Edit `variables.tf` to uncomment the `default` line for the `project` variable and replace `X` with your assigned user number. To uncomment, remove the `#` at the beginning of the line (e.g., change `# default = "userX"` to `default = "user3"` if you are user 3).

---

### Step 13: Create Application Main Configuration

**Copy `main.tf` from the solution directory:**

```bash
cp ~/intermediate/day2/labs/lab5/lab5-solution/application/main.tf ~/lab5-im/application/
```

The file contains:

```hcl
# Local values referencing infrastructure layer outputs
# Key pattern: Local values from terraform_remote_state for cleaner references
locals {
  # These come from the infrastructure layer via terraform_remote_state
  subnet_id    = data.terraform_remote_state.infrastructure.outputs.subnet_id
  sg_id        = data.terraform_remote_state.infrastructure.outputs.security_group_id
  environment  = data.terraform_remote_state.infrastructure.outputs.environment

  # Name prefix for consistent resource naming
  name_prefix = "lab5-${var.project}-${local.environment}"
}

# EC2 instance using infrastructure from the other layer
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = local.subnet_id  # From infrastructure layer
  vpc_security_group_ids = [local.sg_id]    # From infrastructure layer

  user_data = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y httpd
    systemctl start httpd
    systemctl enable httpd

    # Create a simple web page
    cat > /var/www/html/index.html <<'HTMLEOF'
    <!DOCTYPE html>
    <html>
    <head><title>${var.project} Web Server</title></head>
    <body>
      <h1>Web Server</h1>
      <p>Environment: ${local.environment}</p>
    </body>
    </html>
    HTMLEOF
  EOF

  tags = {
    Name = "${local.name_prefix}-web"
  }
}
```

---

### Step 14: Create Application Outputs

**Copy `outputs.tf` from the solution directory:**

```bash
cp ~/intermediate/day2/labs/lab5/lab5-solution/application/outputs.tf ~/lab5-im/application/
```

The file contains:

```hcl
output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "EC2 public IP address"
  value       = aws_instance.web.public_ip
}

# Show what we got from infrastructure layer
output "infrastructure_outputs_used" {
  description = "Values consumed from infrastructure layer"
  value = {
    subnet_id        = local.subnet_id
    security_group   = local.sg_id
    environment      = local.environment
  }
}
```

---

### Step 15: Deploy Application Layer

```bash
cd ~/lab5-im/application

# Initialize with backend
terraform init

# Plan
terraform plan

# Apply
terraform apply
```

**Verify:**
```bash
# See outputs
terraform output

# Check what we got from infrastructure
terraform output infrastructure_outputs_used
```

---

### Step 16: Demonstrate Update Flow

Let's see what happens when we update infrastructure:

```bash
cd ~/lab5-im/infrastructure
```
```hcl
# Add another ingress rule to the web security group
# Edit main.tf and add a new security group rule resource:
#
resource "aws_vpc_security_group_ingress_rule" "web_custom" {
   security_group_id = aws_security_group.web_sg.id
   description       = "Custom app port"
   from_port         = 8080
   to_port           = 8080
   ip_protocol       = "tcp"
   cidr_ipv4         = "0.0.0.0/0"

  tags = {
     Name = "${local.name_prefix}-web-custom"
   }
 }
```

```bash
# Apply the infrastructure change
terraform apply
```

Now check the application layer:

```bash
cd ~/lab5-im/application

# Plan to see if it detects changes
terraform plan
```

The application layer should show **no changes** because we only modified the security group rules, not the security group ID that the application references.

---

## Verification Checklist

```bash
# 1. Check infrastructure outputs
cd ~/lab5-im/infrastructure && terraform output

# 2. Check application outputs
cd ~/lab5-im/application && terraform output

# 3. Verify instances are using infrastructure layer resources
terraform output infrastructure_outputs_used
```

---

## Key Concepts Recap

### terraform_remote_state Data Source

```hcl
data "terraform_remote_state" "infrastructure" {
  backend = "s3"
  config = {
    bucket = "my-state-bucket"
    key    = "path/to/terraform.tfstate"
    region = "us-west-1"
  }
}

# Access outputs
local.subnet_id = data.terraform_remote_state.infrastructure.outputs.subnet_id
```

### Outputs as Interface

Infrastructure layer outputs define what application layer can use:

```hcl
# Infrastructure outputs.tf
output "subnet_id" {
  value = aws_subnet.app.id
}

# Application accesses it via:
data.terraform_remote_state.infrastructure.outputs.subnet_id
```

### Deployment Order

1. **Infrastructure first** - Creates foundation resources
2. **Application second** - Depends on infrastructure outputs
3. **Destroy in reverse** - Application first, then infrastructure

### Benefits of Layered Architecture

| Benefit | Description |
|---------|-------------|
| Blast Radius | Changes to app don't risk infrastructure |
| Team Separation | Different teams own different layers |
| Deployment Flexibility | Update layers independently |
| State Size | Smaller state files, faster operations |


## Next Steps: Polyrepo Pattern with CI/CD (Optional Advanced Exercise)

Now that you've learned layered architecture with directory-based separation, the next evolution is the **polyrepo pattern** - storing each layer in its own Git repository with independent CI/CD pipelines.

### Why Polyrepo?

| Benefit | Description |
|---------|-------------|
| Team Ownership | Different teams can own infrastructure vs application |
| Independent Releases | Deploy layers on separate schedules |
| Access Control | Restrict who can modify network vs app code |
| Focused Pipelines | Each repo has its own CI/CD configuration |

### Part D: Install GitHub CLI and Authenticate

Before creating repositories, install the GitHub CLI (`gh`) tool which makes it easier to authenticate and work with GitHub from the command line.

**Step 1: Install GitHub CLI**

```bash
# Copy and run the install script
cp ~/im/day2/labs/lab5/lab5-solution/install-gh.sh ~/lab5-im/
cd ~/lab5-im
bash install-gh.sh
```

**Step 2: Authenticate with GitHub**

```bash
gh auth login
```

Follow the prompts:
1. Select **GitHub.com**
2. Select **HTTPS** as preferred protocol
3. When asked to authenticate, select **Login with a web browser**
4. Copy the one-time code shown in the terminal
5. Press Enter to open the browser and paste the code
6. Authorize the GitHub CLI

**Step 3: Verify Authentication**

```bash
gh auth status
```

You should see a message confirming you are logged in to github.com. **Verify the logged-in username matches your GitHub account.**

If the wrong user is active, switch accounts:
```bash
gh auth switch
```

**Step 4: Configure Git Identity**

Set your Git name and email to match your GitHub account:

```bash
git config --global user.name "Your Name"
git config --global user.email "your-email@example.com"
```

---

### Part E: Create Separate Repositories

**Step 1: Create Infrastructure Repository**

Use `gh repo create` to create the repository and set up the remote in one command:

```bash
cd ~/lab5-im/infrastructure
git init
cp ~/im/day2/labs/lab5/lab5-solution/.gitignore .
git add .
git commit -m "Initial commit: Infrastructure layer"
git branch -M main
gh repo create terraform-infrastructure-userX --private --source=. --remote=origin --push
git checkout -b develop
cp ~/im/day2/labs/lab5/lab5-solution/infrastructure/Jenkinsfile .
git add Jenkinsfile
git commit -m "Add Jenkins pipeline configuration"
git push -u origin develop
```

**Step 2: Create Application Repository**

```bash
cd ~/lab5-im/application
git init
cp ~/im/day2/labs/lab5/lab5-solution/.gitignore .
git add .
git commit -m "Initial commit: Application layer"
git branch -M main
gh repo create terraform-application-userX --private --source=. --remote=origin --push
git checkout -b develop
cp ~/im/day2/labs/lab5/lab5-solution/application/Jenkinsfile .
git add Jenkinsfile
git commit -m "Add Jenkins pipeline configuration"
git push -u origin develop
```

---

### Part F: Create Personal Access Token and Jenkins Pipelines

**Step 1: Create GitHub Account (if needed)**

If you didn't complete the beginner course and don't have a GitHub account:
1. Go to [github.com](https://github.com)
2. Click **Sign up**
3. Follow the registration process

**Step 2: Create Personal Access Token**

Create a token that works with all your repositories:

1. Go to GitHub → **Settings** → **Developer settings** → **Personal access tokens** → **Fine-grained tokens**
2. Click **Generate new token**
3. Name: `default-token`
4. Set expiration as needed
5. Under **Repository access**, select **All repositories**
6. Under **Permissions**, set:
   - **Commit statuses**: Read and write
   - **Contents**: Read and write
   - **Metadata**: Read-only (auto-selected)
   - **Pull requests**: Read and write
7. Click **Generate token**
8. **Copy and save the token** - you won't see it again!

**Step 3: Create Jenkins Multibranch Pipeline for Application (FIRST)**

> **Important:** Create the application pipeline FIRST because the infrastructure pipeline will reference it by name in the trigger stage.

1. Go to Jenkins dashboard → **New Item**
2. Name: `terraform-application-userX` (replace userX)
3. Select **Multibranch Pipeline** → Click **OK**
4. In configuration:
   - **Branch Sources** → Click **Add source** → Select **GitHub** (NOT "Git"!)
   - **Repository HTTPS URL**: `https://github.com/YOUR_USERNAME/terraform-application-userX.git`
   - **Credentials**: Click **Add** → Add your PAT as username/password (name it `default-token`)
5. **Build Configuration**: by Jenkinsfile
6. **Scan Multibranch Pipeline Triggers**: Check **Periodically if not otherwise run** → **1 minute**
7. Click **Save**

> **Important:** Select **GitHub** as the source type, not "Git". GitHub provides better integration with PRs and branch discovery.

**Step 4: Create Jenkins Multibranch Pipeline for Infrastructure**

Repeat Step 3 with:
- Name: `terraform-infrastructure-userX`
- Repository URL: `https://github.com/YOUR_USERNAME/terraform-infrastructure-userX.git`
- Same credentials (`default-token`)

The infrastructure Jenkinsfile triggers the application pipeline by name, so the application pipeline must exist first.

**Step 5: Update Infrastructure Jenkinsfile with Application Pipeline Name**

Edit the Jenkinsfile in your infrastructure repository to use your actual application pipeline name:

```bash
cd ~/lab5-im/infrastructure
```

Open `Jenkinsfile` and find this line in the "Trigger Application Pipeline" stage:
```groovy
build job: "terraform-application-userX/${env.BRANCH_NAME}",
```

Replace `userX` with your user number (e.g., `terraform-application-user1`).

Commit and push the change:
```bash
git add Jenkinsfile
git commit -m "Update application pipeline name in trigger"
git push origin develop
```

**Step 6: Test Pipeline by Triggering an Infrastructure Change**

Now let's test that the pipeline works by making a change to the infrastructure:

```bash
cd ~/lab5-im/infrastructure
```

Edit `main.tf` and find the `web_custom` security group rule:

```hcl
resource "aws_vpc_security_group_ingress_rule" "web_custom" {
  security_group_id = aws_security_group.web_sg.id
  from_port         = var.custom_port
  to_port           = var.custom_port
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"  # Change this line
  description       = "Custom application port"

  tags = local.common_tags
}
```

Change `cidr_ipv4` from `"0.0.0.0/0"` to a private IP range:

```hcl
  cidr_ipv4         = "10.0.0.0/8"  # Restrict to private network
```

Commit and push:
```bash
git add main.tf
git commit -m "Restrict custom port access to private network"
git push origin develop
```

**Watch the Pipeline:**

1. Go to Jenkins → `terraform-infrastructure-userX`
2. Wait for the scan to detect the change (up to 1 minute) or click **Scan Multibranch Pipeline Now**
3. Click on the `develop` branch build
4. Watch the pipeline execute:
   - Checkout → Init → Validate → Plan (should detect changes)
   - Approval prompt appears → Click **Approve**
   - Apply executes the infrastructure change
   - **Trigger Application Pipeline** stage runs automatically
5. The application pipeline starts and waits for approval

This demonstrates the full workflow where infrastructure changes trigger the application pipeline.

---

### Part G: Understanding the Jenkinsfiles

Review the Jenkinsfiles you copied to understand their structure.

**Infrastructure Jenkinsfile Features:**

- Standard Terraform workflow: init → validate → plan → apply
- Approval gate before apply (only on develop and main branches)
- **Trigger Application Pipeline** stage: After successful infrastructure apply, it triggers the application pipeline automatically
- Replace `userX` with your user number in the `build job` line

**Application Jenkinsfile Features:**

- Standard Terraform workflow: init → validate → plan → apply
- Approval gate before apply (only on develop and main branches)
- Reads infrastructure outputs via `terraform_remote_state` (configured in data.tf)

### Key Polyrepo Concepts

1. **Shared State Bucket, Different Keys**
   - Both repos use the same S3 bucket for state
   - Infrastructure: `lab5/infrastructure/terraform.tfstate`
   - Application: `lab5/application/terraform.tfstate`

2. **Dependency via Remote State**
   - Application reads infrastructure outputs via `terraform_remote_state`
   - Infrastructure pipeline triggers application pipeline after successful apply

3. **Deployment Order**
   - Infrastructure always deploys first
   - Application pipeline is triggered by infrastructure pipeline
   - Each pipeline has its own approval gate

---

## Documentation Links

- [terraform_remote_state Data Source](https://developer.hashicorp.com/terraform/language/state/remote-state-data)
- [S3 Backend Configuration](https://developer.hashicorp.com/terraform/language/settings/backends/s3)
- [Data Sources](https://developer.hashicorp.com/terraform/language/data-sources)
