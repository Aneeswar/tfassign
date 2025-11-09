output "frontend_url" {
  description = "URL to access the Express frontend"
  value       = "http://${aws_instance.frontend.public_ip}:${var.frontend_port}"
}