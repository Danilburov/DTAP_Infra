// Security groups for ALB, app, and RDS

// ALB SG: allow HTTP from anywhere
resource "aws_security_group" "alb_sg" {
  name        = "${var.project}-alb-sg"
  description = "ALB security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project}-alb-sg" })
}

// App SG: allow HTTP from ALB and node_exporter from monitoring
resource "aws_security_group" "app_sg" {
  name        = "${var.project}-app-sg"
  description = "App instances security group"
  vpc_id      = aws_vpc.main.id

  // HTTP from ALB
  ingress {
    description = "HTTP from ALB"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  // node_exporter from monitoring SG
  ingress {
    description = "node_exporter from monitoring"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    security_groups = [aws_security_group.monitoring_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project}-app-sg" })
}

// RDS SG: allow Postgres from app
resource "aws_security_group" "rds_sg" {
  name        = "${var.project}-rds-sg"
  description = "RDS security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Postgres from app"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project}-rds-sg" })
}

# ALB mag HTTP vanaf internet
resource "aws_security_group" "alb_sg" {
  name        = "${var.project}-alb-sg"
  description = "HTTP vanaf internet naar ALB"
  vpc_id      = aws_vpc.main.id
  tags        = var.tags

  ingress {
    description = "HTTP 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# App-EC2 mag alleen HTTP ontvangen van de ALB
resource "aws_security_group" "app_sg" {
  name        = "${var.project}-app-sg"
  description = "HTTP vanaf ALB naar app-EC2"
  vpc_id      = aws_vpc.main.id
  tags        = var.tags

  ingress {
    description     = "HTTP van ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  

  # node_exporter vanaf monitoring-EC2 (via monitoring_sg)
  ingress {
    description     = "node_exporter 9100 from monitoring SG"
    from_port       = 9100
    to_port         = 9100
    protocol        = "tcp"
    security_groups = [aws_security_group.monitoring_sg.id]
  }

}

# RDS accepteert alleen vanaf app_sg (poort 5432)
resource "aws_security_group" "rds_sg" {
  name        = "${var.project}-rds-sg"
  description = "Postgres vanaf app-EC2"
  vpc_id      = aws_vpc.main.id
  tags        = var.tags

  ingress {
    description     = "Postgres 5432"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



