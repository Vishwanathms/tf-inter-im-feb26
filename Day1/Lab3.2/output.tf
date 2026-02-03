output "redis_private_ip" {
  value = aws_instance.redis.private_ip
}

output "python_public_url" {
  value = "http://${aws_instance.python.public_ip}:5000"
}

output "python_public_ip" {
  value = aws_instance.python.public_ip
}
