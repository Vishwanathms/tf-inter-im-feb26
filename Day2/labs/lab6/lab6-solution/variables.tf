variable "project" {
  description = "Use userX format, replace X with your user number. Uncomment default to avoid prompt."
  type        = string
  # default   = "userX"
}

locals {
  name_prefix = "lab6-${var.project}"
}
