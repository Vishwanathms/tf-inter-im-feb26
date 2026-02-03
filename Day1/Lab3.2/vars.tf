variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" {
  type    = string
  default = "demo"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

# Existing EC2 keypair name in the region
variable "key_name" {
  type = string
}

# Your public IP in CIDR, e.g. "49.37.x.x/32"
variable "ssh_cidr" {
  type    = string
  default = "0.0.0.0/0"
}
