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
