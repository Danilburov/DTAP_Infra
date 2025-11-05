// VPN: minimal OpenVPN server with EIP in public subnet A

// Ubuntu Jammy AMI
data "aws_ami" "ubuntu_jammy" {
  most_recent = true
  owners      = ["099720109477"] // Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

// VPN security group
resource "aws_security_group" "vpn" {
  name        = "${var.project}-vpn-sg"
  description = "OpenVPN SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "OpenVPN UDP"
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project}-vpn-sg" })
}

// Elastic IP for VPN
resource "aws_eip" "vpn" {
  domain = "vpc"
  tags   = merge(var.tags, { Name = "${var.project}-vpn-eip" })
}

// OpenVPN instance
resource "aws_instance" "openvpn" {
  ami                         = data.aws_ami.ubuntu_jammy.id
  instance_type               = var.vpn_instance_type
  subnet_id                   = aws_subnet.public_a.id
  vpc_security_group_ids      = [aws_security_group.vpn.id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  user_data = <<-BASH
    #!/usr/bin/env bash
    set -eux
    apt-get update -y
    apt-get install -y curl
    # Install OpenVPN using Nyr script (non-interactive)
    curl -O https://raw.githubusercontent.com/Nyr/openvpn-install/master/openvpn-install.sh
    chmod +x openvpn-install.sh
    AUTO_INSTALL=y APPROVE_INSTALL=y ENDPOINT=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4) \
      ./openvpn-install.sh
    # Push VPC DNS (AmazonProvidedDNS at base+2)
    echo 'push "dhcp-option DNS 10.0.0.2"' >> /etc/openvpn/server/server.conf || true
    systemctl restart openvpn-server@server || true
  BASH

  tags = merge(var.tags, { Name = "${var.project}-vpn" })
}

// Associate EIP to VPN
resource "aws_eip_association" "vpn" {
  instance_id   = aws_instance.openvpn.id
  allocation_id = aws_eip.vpn.id
}


