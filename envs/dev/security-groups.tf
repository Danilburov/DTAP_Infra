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
//Created a new SG for the backend ALB and frontend ALB
resource "aws_security_group" "dtap-backend-alb-sg"{
  name = "dtap-backend-alb-sg"
  description = "SG for the backend ALB"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "dtap-frontend-alb-sg"{
  name = "dtap-frontend-alb-sg"
  description = "SG for the frontend ALB"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
// App SG: allow HTTP from ALB and node_exporter from monitoring
resource "aws_security_group" "app_sg" {
  name        = "${var.project}-app-sg"
  description = "App instances security group"
  vpc_id      = aws_vpc.main.id

  // HTTP from ALB
  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  // node_exporter from monitoring SG
  ingress {
    description     = "node_exporter from monitoring"
    from_port       = 9100
    to_port         = 9100
    protocol        = "tcp"
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
  ingress{
    description = "Open connection" //Bad practise, I am just opening it for accessibility and easy testing
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project}-rds-sg" })
}

//SGs for both the frontend-dev/prod and backend-dev/prod ECS services
resource "aws_security_group" "ecs_service_backend_sg" {
  name = "ecs_service_backend_sg"
  description = "SG for both ECS services backend-dev/prod"
  vpc_id = aws_vpc.main.id

  ingress{
    description = "traffic from backend ALB"
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    security_groups = [aws_security_group.dtap-backend-alb-sg.id]
  }
  ingress{
    description = "Open connection" //bad practise
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress{
    description = "all outbound traffic"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "ecs_service_frontend_sg" {
  name = "ecs_service_frontend_sg"
  description = "SG for both ECS services frontend-dev/prod"
  vpc_id = aws_vpc.main.id

  ingress{
    description = "traffic from backend ALB"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [aws_security_group.dtap-backend-alb-sg.id]
  }
  ingress{
    description = "Open connection" //bad practise
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress{
    description = "all outbound traffic"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

