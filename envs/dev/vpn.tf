/*
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


*/
# Ubuntu 22.04 LTS (Jammy) AMI in eu-central-1
data "aws_ami" "ubuntu_jammy" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group voor OpenVPN
# - UDP/1194 vanaf internet
# - (optioneel) SSH/22 alleen vanaf jouw IP (pas var.my_ip_cidr aan)
resource "aws_security_group" "vpn" {
  name        = "${var.project}-vpn-sg"
  description = "OpenVPN server security group"
  vpc_id      = aws_vpc.main.id

  tags = var.tags

  # OpenVPN ingress
  ingress {
    description = "OpenVPN UDP 1194"
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH (optioneel: alleen vanaf jouw IP)
  ingress {
    description = "SSH 22 from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  # Egress alles
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Reference the persistent EIP from the persistent stack
data "terraform_remote_state" "persistent" {
  backend = "s3"
  config = {
    bucket = "dtap-terraform-state-bucket"
    key = "envs/persistent/terraform.tfstate"
    region = "eu-central-1"
    dynamodb_table = "dtap-terraform-state-lock"
  }
}

# Reference the persistent EIP
data "aws_eip" "vpn_eip" {
  id = data.terraform_remote_state.persistent.outputs.vpn_eip_allocation_id
}

resource "aws_eip_association" "vpn_assoc" {
  instance_id   = aws_instance.openvpn.id
  allocation_id = data.aws_eip.vpn_eip.id
}

# OpenVPN EC2 instance
resource "aws_instance" "openvpn" {
  ami                         = data.aws_ami.ubuntu_jammy.id
  instance_type               = var.vpn_instance_type
  subnet_id                   = aws_subnet.public_a.id
  vpc_security_group_ids      = [aws_security_group.vpn.id]
  associate_public_ip_address = true
  key_name                    = var.key_name # vul in bij variables.tf

  tags = merge(var.tags, {
    Name = "${var.project}-openvpn"
  })

  iam_instance_profile = aws_iam_instance_profile.vpn_profile.name

  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail
    export DEBIAN_FRONTEND=noninteractive
    echo "[vpn] starting cloud-init at $(date)"

    apt-get update -y
    apt-get install -y wget curl awscli

    BUCKET="${data.terraform_remote_state.persistent.outputs.vpn_pki_bucket_name}"
    PKI_ARCHIVE="s3://$BUCKET/pki.tgz"

    # First, install OpenVPN (needed whether restoring or fresh install)
    wget -O /root/openvpn-install.sh https://raw.githubusercontent.com/Nyr/openvpn-install/master/openvpn-install.sh
    chmod +x /root/openvpn-install.sh

    # Use the EIP as endpoint (stays the same)
    ENDPOINT="${data.terraform_remote_state.persistent.outputs.vpn_eip_public_ip}"

    # Check if PKI already exists in S3
    if aws s3 ls "$PKI_ARCHIVE" >/dev/null 2>&1; then
        echo "[vpn] PKI found in S3, will restore after installation..."
        
        # Install OpenVPN fresh first
        export AUTO_INSTALL=y
        export PROTOCOL_CHOICE=1 # UDP
        export PORT_CHOICE=1 # 1194
        export DNS=1 # default resolvers
        export ENDPOINT="$ENDPOINT"
        export CLIENT=student

        bash /root/openvpn-install.sh

        # Now restore the PKI
        echo "[vpn] Restoring PKI from S3..."
        aws s3 cp "$PKI_ARCHIVE" /tmp/pki.tgz
        tar -xzf /tmp/pki.tgz -C /
        
        # FIX: Update server.conf to use 0.0.0.0 instead of old IP
        echo "[vpn] Fixing server.conf to bind to 0.0.0.0..."
        sudo sed -i 's/^local .*/local 0.0.0.0/' /etc/openvpn/server/server.conf || true
        
        # Restart the service
        systemctl restart openvpn-server@server || systemctl restart openvpn@server || true
    else
        echo "[vpn] No PKI found, fresh install..."
        
        export AUTO_INSTALL=y
        export PROTOCOL_CHOICE=1 # UDP
        export PORT_CHOICE=1 # 1194
        export DNS=1 # default resolvers
        export ENDPOINT="$ENDPOINT"
        export CLIENT=student

        bash /root/openvpn-install.sh

        # push VPC DNS
        echo 'push "dhcp-option DNS 10.0.0.2"' >> /etc/openvpn/server.conf
        systemctl restart openvpn-server@server || systemctl restart openvpn@server || true

        # PKI opslaan
        sleep 2
        tar -czf /tmp/pki.tgz /etc/openvpn
        aws s3 cp /tmp/pki.tgz "$PKI_ARCHIVE"
        echo "[vpn] PKI uploaded to $PKI_ARCHIVE"
    fi

    # Profiel beschikbaar maken
    if [ -f /root/student.ovpn ]; then
        cp /root/student.ovpn /home/ubuntu/student.ovpn
        chown ubuntu:ubuntu /home/ubuntu/student.ovpn
    elif [ -f /root/client.ovpn ]; then
        cp /root/client.ovpn /home/ubuntu/student.ovpn
        chown ubuntu:ubuntu /home/ubuntu/student.ovpn
    else
        echo "[vpn] Looking for .ovpn files..."
        ls -la /root/*.ovpn 2>/dev/null || echo "No .ovpn files in /root/"
    fi

    echo "[vpn] finished cloud-init at $(date)"
  EOF
}

# S3 bucket is now in the persistent stack
# Reference it via data.terraform_remote_state.persistent.outputs

resource "aws_iam_role" "vpn_role" {
  name = "${var.project}-vpn-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "vpn_s3_policy" {
  name = "${var.project}-vpn-s3-policy"
  role = aws_iam_role.vpn_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["s3:PutObject","s3:GetObject","s3:ListBucket"],
      Resource = [
        data.terraform_remote_state.persistent.outputs.vpn_pki_bucket_arn,
        "${data.terraform_remote_state.persistent.outputs.vpn_pki_bucket_arn}/*"
      ]
    }]
  })
}

resource "aws_iam_instance_profile" "vpn_profile" {
  name = "${var.project}-vpn-profile"
  role = aws_iam_role.vpn_role.name
}
