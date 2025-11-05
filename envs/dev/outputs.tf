output "vpc_id"{ 
    value = aws_vpc.main.id 
}
output "public_subnet_id"{
    value = aws_subnet.public.id
}
output "private_subnet_ids"{
    value = [for s in aws_subnet.private : s.id]
}

output "rds_endpoint"{
    value = aws_db_instance.postgres.address
}
output "rds_port"{
    value = aws_db_instance.postgres.port
}
output "rds_db_name"{
    value = aws_db_instance.postgres.db_name
}
output "rds_username"{
    value = aws_db_instance.postgres.username
}
output "client_vpn_endpoint_id" {
  value       = try(aws_ec2_client_vpn_endpoint.team[0].id, "")
  description = "Empty until you set server_cert_arn"
}
