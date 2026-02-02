# Infrastructure Layer Outputs
# These outputs are consumed by the application layer via terraform_remote_state
# Key concept: Outputs serve as the interface for cross-layer communication

output "subnet_id" {
  description = "ID of the application subnet"
  value       = aws_subnet.app.id
}

output "security_group_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web_sg.id
}

output "environment" {
  description = "Environment name for use in application layer"
  value       = var.environment
}
