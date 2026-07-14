resource "aws_security_group" "ec2_private" {
  name        = "ec2-private-sg"
  description = "Allow ssh, outbound and inbound only from cluster"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "EC2 SG private"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_from_public_SG" {
  security_group_id            = aws_security_group.ec2_private.id
  referenced_security_group_id = aws_security_group.ec2.id
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_fronted_traffic" {
  security_group_id            = aws_security_group.ec2_private.id
  referenced_security_group_id = aws_security_group.ec2.id
  from_port                    = 5000
  ip_protocol                  = "tcp"
  to_port                      = 5000
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4_private_subnet" {
  security_group_id = aws_security_group.ec2_private.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}






resource "aws_instance" "app_server_private" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.custom["private-a"].id
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [aws_security_group.ec2_private.id]
  user_data              = <<-EOF
  #!/bin/bash
  apt-get update -y
  apt-get install -y nginx
  systemctl enable --now nginx
EOF

  tags = {
    Name = var.instance_name
  }

}
