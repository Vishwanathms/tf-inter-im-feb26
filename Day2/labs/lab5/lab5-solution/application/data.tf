# Read infrastructure layer state
# This demonstrates cross-layer dependency using terraform_remote_state
# Key concept: terraform_remote_state reads outputs from another state file

data "terraform_remote_state" "infrastructure" {
  backend = "s3"

  config = {
    bucket = "boa-terraform-state-im-vishwa"  # Replace userX with your user number
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
