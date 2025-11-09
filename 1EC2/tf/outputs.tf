output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.Ec2.public_ip
}

output "frontend_url" {
  description = "URL to access the Express frontend"
  value       = "http://${aws_instance.Ec2.public_ip}:${var.access_port}"
}