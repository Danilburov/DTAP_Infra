locals { name = var.project_name }

data "aws_availability_zones" "available" {}

//VPC and subnet
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "${local.name}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${local.name}-igw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
  tags = { Name = "${local.name}-public-1" }
}

resource "aws_subnet" "private" {
  count                   = length(var.private_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags = { Name = "${local.name}-private-${count.index + 1}" }
}

# Routes
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${local.name}-rtb-public" }
}

resource "aws_route" "public_inet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${local.name}-rtb-private-${count.index + 1}" }
}

resource "aws_route_table_association" "private_assoc" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

//Security group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "${local.name}-rds-sg"
  description = "Postgres access"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name}-rds-sg" }
}

//Private RDS with PostgreSQL
resource "aws_db_subnet_group" "rds" {
  name       = "rds-db-subnet-group"
  subnet_ids = [for s in aws_subnet.private : s.id]
  tags       = { Name = "${local.name}-db-subnet-group" }
}

resource "aws_db_instance" "postgres" {
  identifier             = "group-project-postgres"
  engine                 = "postgres"
  engine_version         = "17.6"
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false
  multi_az               = false
  storage_encrypted      = true
  backup_retention_period= 0
  deletion_protection    = false
  skip_final_snapshot    = true

  tags = { Name = "group-project-postgres" }
}
