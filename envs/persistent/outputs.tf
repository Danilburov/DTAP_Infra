output "vpn_eip_public_ip" {
  description = "Public IP of the VPN Elastic IP"
  value       = aws_eip.vpn_eip.public_ip
}

output "vpn_eip_allocation_id" {
  description = "Allocation ID of the VPN Elastic IP"
  value       = aws_eip.vpn_eip.id
}

output "vpn_pki_bucket_name" {
  description = "Name of the VPN PKI S3 bucket"
  value       = aws_s3_bucket.vpn_pki.bucket
}

output "vpn_pki_bucket_arn" {
  description = "ARN of the VPN PKI S3 bucket"
  value       = aws_s3_bucket.vpn_pki.arn
}