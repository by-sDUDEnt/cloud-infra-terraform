resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "main"
  }
}

locals {
  subnets = {
    public-a  = { cidr = "10.0.0.0/24", type = "public", az = "eu-north-1a" }
    private-a = { cidr = "10.0.1.0/24", type = "private", az = "eu-north-1a" }
    private-b = { cidr = "10.0.2.0/24", type = "private", az = "eu-north-1b" }
  }
}

resource "aws_subnet" "custom" {
  for_each          = local.subnets
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    type = each.value.type
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = aws_vpc.main.cidr_block
    gateway_id = "local"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "route table for public subnet"
  }
}

resource "aws_route_table_association" "public_subnet" {
  subnet_id      = aws_subnet.custom["public-a"].id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat_ip" {
  domain = "vpc"
  tags = {
    Name = "Eip for nat"
  }
}

resource "aws_nat_gateway" "gw_nat" {
  allocation_id = aws_eip.nat_ip.id
  subnet_id     = aws_subnet.custom["public-a"].id

  tags = {
    Name = "gw NAT"
  }

}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = aws_vpc.main.cidr_block
    gateway_id = "local"
  }

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gw_nat.id
  }

  tags = {
    Name = "route table for private subnet"
  }
}

resource "aws_route_table_association" "private_subnet_a" {
  subnet_id      = aws_subnet.custom["private-a"].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_subnet_b" {
  subnet_id      = aws_subnet.custom["private-b"].id
  route_table_id = aws_route_table.private.id
}

