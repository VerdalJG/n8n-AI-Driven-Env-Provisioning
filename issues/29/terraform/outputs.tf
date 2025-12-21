output "dev_ec2_public_ip" {
  value = aws_instance.dev.public_ip
}

output "dev_rds_endpoint" {
  value = aws_db_instance.postgresql.endpoint
}