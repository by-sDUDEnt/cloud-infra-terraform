provider "aws" {
  region = "eu-north-1"
}


resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

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

resource "aws_subnet" "main" {
  for_each          = local.subnets
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    type = each.value.type
  }
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
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  tags = {
    Name = var.instance_name
  }
}
