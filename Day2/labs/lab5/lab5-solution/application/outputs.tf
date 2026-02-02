# Application Layer Outputs

output "instance_id" {
  description = "ID of the web instance"
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "Public IP of the web instance"
  value       = aws_instance.web.public_ip
}

# Summary output showing infrastructure dependencies
output "infrastructure_outputs_used" {
  description = "Values consumed from infrastructure layer"
  value = {
    subnet_id      = local.subnet_id
    security_group = local.sg_id
    environment    = local.environment
  }
}
