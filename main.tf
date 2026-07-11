provider "aws" {
  region = "eu-north-1"
}


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



resource "aws_security_group" "ec2" {
  name        = "ec2-public-sg"
  description = "Allow ssh from my ip and HTTP from the internet"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "EC2 SG"
  }
}


resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.ec2.id
  cidr_ipv4         = var.my_ip
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.ec2.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.ec2.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


resource "aws_key_pair" "main" {
  key_name   = "ec2_ssh_user"
  public_key = file("../../.ssh/ec2_ssh_user.pub")
}


data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "app_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.custom["public-a"].id
  key_name                    = aws_key_pair.main.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  user_data                   = <<-EOF
  #!/bin/bash
  apt-get update -y
  apt-get install -y nginx
  systemctl enable --now nginx
EOF

  tags = {
    Name = var.instance_name
  }

}
