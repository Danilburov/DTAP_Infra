// Networking: VPC, subnets, routing, NAT for DTAP dev

// Get available AZs for the region
data "aws_availability_zones" "this" {
  state = "available"
}

// Local AZ picks and CIDRs
locals {
  az_a = data.aws_availability_zones.this.names[0]
  az_b = data.aws_availability_zones.this.names[1]

  public_cidr_a         = "10.0.1.0/24"
  public_cidr_b         = "10.0.11.0/24"
  private_app_cidr_a    = "10.0.2.0/24"
  private_app_cidr_b    = "10.0.12.0/24"
  private_data_cidr_a   = "10.0.3.0/24"
  private_data_cidr_b   = "10.0.13.0/24"
  private_monitoring_cidr_a = "10.0.50.0/24"
}

// VPC with DNS enabled
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "${var.project}-vpc"
  })
}

// Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.project}-igw"
  })
}

// Public subnets
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_cidr_a
  availability_zone       = local.az_a
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.project}-public-a"
    Tier = "public"
  })
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_cidr_b
  availability_zone       = local.az_b
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.project}-public-b"
    Tier = "public"
  })
}

// Private app subnets
resource "aws_subnet" "private_app_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_app_cidr_a
  availability_zone = local.az_a

  tags = merge(var.tags, {
    Name = "${var.project}-app-a"
    Tier = "app"
  })
}

resource "aws_subnet" "private_app_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_app_cidr_b
  availability_zone = local.az_b

  tags = merge(var.tags, {
    Name = "${var.project}-app-b"
    Tier = "app"
  })
}

// Private data subnets
resource "aws_subnet" "private_data_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_data_cidr_a
  availability_zone = local.az_a

  tags = merge(var.tags, {
    Name = "${var.project}-data-a"
    Tier = "data"
  })
}

resource "aws_subnet" "private_data_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_data_cidr_b
  availability_zone = local.az_b

  tags = merge(var.tags, {
    Name = "${var.project}-data-b"
    Tier = "data"
  })
}

// Private monitoring subnet
resource "aws_subnet" "private_monitoring_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_monitoring_cidr_a
  availability_zone = local.az_a

  tags = merge(var.tags, {
    Name = "${var.project}-monitoring-a"
    Tier = "monitoring"
  })
}

// Public route table and default route to Internet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.project}-dtap-rt-public"
  })
}

resource "aws_route" "public_to_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

// NAT Gateway for private subnets
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.project}-nat-eip"
  })
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id
  depends_on    = [aws_internet_gateway.igw]

  tags = merge(var.tags, {
    Name = "${var.project}-nat"
  })
}

// Private route table and default route to NAT
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.project}-dtap-rt-private"
  })
}

resource "aws_route" "private_to_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

// Associate all private subnets
resource "aws_route_table_association" "app_a" {
  subnet_id      = aws_subnet.private_app_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "app_b" {
  subnet_id      = aws_subnet.private_app_b.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "data_a" {
  subnet_id      = aws_subnet.private_data_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "data_b" {
  subnet_id      = aws_subnet.private_data_b.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "monitoring_a" {
  subnet_id      = aws_subnet.private_monitoring_a.id
  route_table_id = aws_route_table.private.id
}


