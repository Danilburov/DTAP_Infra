// RDS Postgres for app

// Subnet group across data subnets
resource "aws_db_subnet_group" "db_subnets" {
  name       = "${var.project}-db-subnets"
  subnet_ids = [aws_subnet.private_data_a.id, aws_subnet.private_data_b.id]

  tags = merge(var.tags, { Name = "${var.project}-db-subnets" })
}

// Random DB password
resource "random_password" "db_password" {
  length  = 16
  special = false
}

// Postgres instance
resource "aws_db_instance" "app_db" {
  identifier              = "${var.project}-db"
  engine                  = "postgres"
  engine_version          = "16.8"
  instance_class          = var.db_instance_class
  allocated_storage       = 20
  storage_type            = "gp2" // consider gp3
  db_subnet_group_name    = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  username                = "appuser"
  password                = random_password.db_password.result
  publicly_accessible     = false
  multi_az                = false
  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = 1

  tags = var.tags
}


