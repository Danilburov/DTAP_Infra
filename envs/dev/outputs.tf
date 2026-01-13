// Monitoring private IP
output "monitoring_private_ip" {
  description = "Monitoring instance private IP"
  value       = aws_instance.monitoring.private_ip
}