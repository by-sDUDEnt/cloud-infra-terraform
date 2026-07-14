output "instance_hostname" {
  description = "DNS name of the EC2 instance"
  value       = aws_instance.app_server.private_dns
}

output "instance_public_ip" {
  description = "IP of the instance"
  value       = aws_instance.app_server.public_ip
}

output "private_instance_hostname" {
  description = "IP of the instance"
  value       = aws_instance.app_server_private.private_dns
}