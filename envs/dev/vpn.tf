locals { create_vpn = length(var.server_cert_arn) > 0 }


resource "aws_ec2_client_vpn_endpoint" "team" {
  count                  = local.create_vpn ? 1 : 0
  description            = "Team Client VPN"
  server_certificate_arn = var.server_cert_arn

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = var.server_cert_arn
  }

  client_cidr_block = var.client_cidr_block
  split_tunnel      = true

  connection_log_options { enabled = false }

  tags = { Name = "${local.name}-client-vpn" }
}

resource "aws_ec2_client_vpn_network_association" "assoc" {
  count                  = local.create_vpn ? 1 : 0
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.team[0].id
  subnet_id              = aws_subnet.public.id
}

resource "aws_ec2_client_vpn_authorization_rule" "auth" {
  count                  = local.create_vpn ? 1 : 0
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.team[0].id
  target_network_cidr    = var.vpc_cidr
  authorize_all_groups   = true
}

resource "aws_security_group_rule" "rds_from_vpn" {
  count                    = local.create_vpn ? 1 : 0
  type                     = "ingress"
  description              = "Postgres from VPN clients"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_sg.id
  cidr_blocks              = [var.client_cidr_block]
}

resource "aws_ec2_client_vpn_route" "to_vpc" {
  count                   = local.create_vpn ? 1 : 0
  client_vpn_endpoint_id  = aws_ec2_client_vpn_endpoint.team[0].id
  destination_cidr_block  = var.vpc_cidr
  target_vpc_subnet_id    = aws_subnet.public.id
  description             = "Route to VPC"
}
