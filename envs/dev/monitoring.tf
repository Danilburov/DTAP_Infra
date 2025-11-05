// Monitoring: subnet, SG, IAM, instance with Prometheus and Grafana

// Monitoring subnet CIDR
locals {
  monitoring_cidr = "10.0.50.0/24"
}

// Subnet for monitoring in AZ A associated to private route table
resource "aws_subnet" "monitoring_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.monitoring_cidr
  availability_zone = local.az_a

  tags = merge(var.tags, {
    Name = "${var.project}-monitoring-a"
    Tier = "monitoring"
  })
}

resource "aws_route_table_association" "monitoring_a_private" {
  subnet_id      = aws_subnet.monitoring_a.id
  route_table_id = aws_route_table.private.id
}

// Security group for monitoring
resource "aws_security_group" "monitoring_sg" {
  name        = "${var.project}-monitoring-sg"
  description = "Monitoring SG"
  vpc_id      = aws_vpc.main.id

  // Allow Grafana 3000 and Prometheus 9090 from VPN and VPN SG
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    cidr_blocks     = ["10.8.0.0/24"]
    security_groups = [aws_security_group.vpn.id]
  }

  ingress {
    from_port       = 9090
    to_port         = 9090
    protocol        = "tcp"
    cidr_blocks     = ["10.8.0.0/24"]
    security_groups = [aws_security_group.vpn.id]
  }

  // Optional SSH from VPN SG
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.vpn.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project}-monitoring-sg" })
}

// AMI for monitoring host
data "aws_ami" "al2023_monitoring" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

// Prometheus config content
locals {
  prometheus_yml = <<-YAML
    global:
      scrape_interval: 15s

    scrape_configs:
      - job_name: 'prometheus'
        static_configs:
          - targets: ['localhost:9090']

      - job_name: 'node'
        ec2_sd_configs:
          - region: ${var.region}
            port: 9100
        relabel_configs:
          - source_labels: [__meta_ec2_tag_Name]
            regex: "${var.project}-app"
            action: keep
          - source_labels: [__meta_ec2_instance_state]
            regex: running
            action: keep
  YAML
}

// User data to install Docker, Prometheus, Grafana
locals {
  monitoring_user_data = <<-BASH
    #!/usr/bin/env bash
    set -eux
    dnf update -y
    dnf install -y docker
    systemctl enable --now docker

    mkdir -p /etc/prometheus
    cat > /etc/prometheus/prometheus.yml << 'EOF'
    ${local.prometheus_yml}
    EOF

    docker run -d --name grafana -p 3000:3000 \
      -e GF_SECURITY_ADMIN_PASSWORD=admin --restart unless-stopped grafana/grafana:10.4.3

    docker run -d --name prometheus -p 9090:9090 \
      -v /etc/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro \
      --restart unless-stopped prom/prometheus:v2.55.1 \
      --config.file=/etc/prometheus/prometheus.yml
  BASH
}

// IAM role allowing EC2 describe for service discovery
data "aws_iam_policy_document" "monitoring_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "monitoring_role" {
  name               = "${var.project}-monitoring-role"
  assume_role_policy = data.aws_iam_policy_document.monitoring_assume.json
}

data "aws_iam_policy_document" "monitoring_inline" {
  statement {
    actions   = ["ec2:DescribeInstances", "ec2:DescribeTags"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "monitoring_policy" {
  name   = "${var.project}-monitoring-ec2-describe"
  role   = aws_iam_role.monitoring_role.id
  policy = data.aws_iam_policy_document.monitoring_inline.json
}

resource "aws_iam_instance_profile" "monitoring_profile" {
  name = "${var.project}-monitoring-profile"
  role = aws_iam_role.monitoring_role.name
}

// Monitoring instance without public IP
resource "aws_instance" "monitoring" {
  ami                         = data.aws_ami.al2023_monitoring.id
  instance_type               = var.app_instance_type
  subnet_id                   = aws_subnet.monitoring_a.id
  vpc_security_group_ids      = [aws_security_group.monitoring_sg.id]
  associate_public_ip_address = false
  key_name                    = var.key_name
  iam_instance_profile        = aws_iam_instance_profile.monitoring_profile.name
  user_data                   = local.monitoring_user_data

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
  }

  tags = merge(var.tags, { Name = "${var.project}-monitoring" })
}


