output "dev_ec2_public_ip" {
  value = aws_instance.dev.public_ip
}