# VPC

resource "aws_vpc" "main" {

  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    var.tags,
    {
      Name = "monitoring-vpc"
    }
  )
}

# Public Subnet 1

resource "aws_subnet" "public_1" {

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_1
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = "public-subnet-1"
    }
  )
}

# Public Subnet 2

resource "aws_subnet" "public_2" {

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_2
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = "public-subnet-2"
    }
  )
}

# Private Subnet 1

resource "aws_subnet" "private_1" {

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_1
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = merge(
    var.tags,
    {
      Name = "private-subnet-1"
    }
  )
}

# Private Subnet 2

resource "aws_subnet" "private_2" {

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_2
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = merge(
    var.tags,
    {
      Name = "private-subnet-2"
    }
  )
}

# Internet Gateway

resource "aws_internet_gateway" "igw" {

  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "main-igw"
    }
  )
}

# Elastic IP

resource "aws_eip" "nat_eip" {

  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "nat-eip"
    }
  )
}

# NAT Gateway

resource "aws_nat_gateway" "nat" {

  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_1.id

  depends_on = [
    aws_internet_gateway.igw
  ]

  tags = merge(
    var.tags,
    {
      Name = "main-nat"
    }
  )
}

# Public Route Table

resource "aws_route_table" "public_rt" {

  vpc_id = aws_vpc.main.id

  route {

    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(
    var.tags,
    {
      Name = "public-route-table"
    }
  )
}

# Public Route Association 1

resource "aws_route_table_association" "public_assoc_1" {

  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}

# Public Route Association 2

resource "aws_route_table_association" "public_assoc_2" {

  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}

# Private Route Table

resource "aws_route_table" "private_rt" {

  vpc_id = aws_vpc.main.id

  route {

    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = merge(
    var.tags,
    {
      Name = "private-route-table"
    }
  )
}

# Private Route Association 1

resource "aws_route_table_association" "private_assoc_1" {

  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_rt.id
}

# Private Route Association 2

resource "aws_route_table_association" "private_assoc_2" {

  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_rt.id
}