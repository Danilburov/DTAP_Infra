# =========================
# AMI voor Ubuntu 22.04
# =========================
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu*22.04*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  owners = ["099720109477"]
}

################################
# SECURITY GROUP
################################
resource "aws_security_group" "monitoring_sg" {
  name   = "monitoring-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "SSH (internal)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.vpn.id]
  }

  ingress {
    description = "Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    security_groups = [aws_security_group.vpn.id]
  }

  # Allow VPN client subnet (OpenVPN tun) to reach monitoring services
  ingress {
    description = "SSH from VPN clients"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.8.0.0/24"]
  }

  ingress {
    description = "Grafana from VPN clients"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["10.8.0.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "monitoring-sg"
  }
}

################################
# S3 DASHBOARD
################################
resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "dashboards" {
  bucket = "grafana-dashboards-${random_id.suffix.hex}"
}

resource "aws_s3_object" "dashboard" {
  bucket       = aws_s3_bucket.dashboards.bucket
  key          = "dashboards/cloudwatch_dashboard.json"
  source       = "${path.module}/grafana_dashboard.json"
  content_type = "application/json"
}

################################
# SNS
################################
resource "aws_sns_topic" "alerts" {
  name = "monitoring-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

################################
# IAM
################################
data "aws_iam_policy_document" "assume_ec2" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "monitoring" {
  name               = "monitoring-role"
  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json
}

data "aws_iam_policy_document" "monitoring_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.dashboards.arn}/*"]
  }

  statement {
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.alerts.arn]
  }

  statement {
    actions = [
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics",
      "cloudwatch:PutMetricData",
      "cloudwatch:GetMetricData"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeTags"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "rds:DescribeDBInstances",
      "rds:ListTagsForResource"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeTags"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "monitoring" {
  role   = aws_iam_role.monitoring.id
  policy = data.aws_iam_policy_document.monitoring_policy.json
}

resource "aws_iam_instance_profile" "monitoring" {
  name = "monitoring-profile"
  role = aws_iam_role.monitoring.name
}

################################
# EC2 ALL-IN-ONE MONITORING
################################
resource "aws_instance" "monitoring" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.private_monitoring_a.id
  vpc_security_group_ids      = [aws_security_group.monitoring_sg.id]
  key_name                    = var.key_name
  iam_instance_profile        = aws_iam_instance_profile.monitoring.name
  associate_public_ip_address = false

  user_data = file("monitoring-userdata.sh")

  tags = {
    Name = "dtap-monitoring"
  }
}