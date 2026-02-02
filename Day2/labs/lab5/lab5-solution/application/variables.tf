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
