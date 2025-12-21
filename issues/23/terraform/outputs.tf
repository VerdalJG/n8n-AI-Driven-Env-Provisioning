output "dev_instance_public_ip" {
  description = "Public IP of the dev EC2 instance"
  value       = aws_instance.dev.public_ip
}

output "rds_endpoint" {
  description = "Endpoint of the RDS database"
  value       = aws_db_instance.postgresql.endpoint
}