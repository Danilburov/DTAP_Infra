



# VPN Elastic IP - persistent across main stack lifecycle
resource "aws_eip" "vpn_eip" {
  domain = "vpc"
  tags = merge(var.tags, {
    Name = "${var.project}-vpn-eip"
  })

  lifecycle {
    prevent_destroy = true
  }

}

# VPN PKI S3 Bucket - persistent across main stack lifecycle
resource "aws_s3_bucket" "vpn_pki" {
  bucket        = "dtap-vpn-pki"
  force_destroy = false # Prevent accidental deletion
  tags          = var.tags

  lifecycle {
    prevent_destroy = true
  }













  # Optional hardening (commented out by default)
  # server_side_encryption_configuration {
  #   rule {
  #     apply_server_side_encryption_by_default {
  #       sse_algorithm = "AES256"
  #     }
  #   }
  # }
  # public_access_block {
  #   block_public_acls       = true
  #   block_public_policy     = true
  #   ignore_public_acls      = true
  #   restrict_public_buckets = true
  # }
}
