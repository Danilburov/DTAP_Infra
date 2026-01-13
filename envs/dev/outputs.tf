// Output key resources for DTAP dev

// ALB DNS name
output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.app_alb.dns_name
}

// RDS endpoint
output "rds_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.app_db.address
}

// Private zone ID
output "private_zone_id" {
  description = "Private Route53 zone ID"
  value       = aws_route53_zone.private_zone.zone_id
}

// VPC ID
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

// Monitoring private IP
output "monitoring_private_ip" {
  description = "Monitoring instance private IP"
  value       = aws_instance.monitoring.private_ip
}