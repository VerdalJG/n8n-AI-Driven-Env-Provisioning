output "vpc_id" {
  value = aws_vpc.main_vpc.id
}

output "public_subnet_ids" {
  value = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

output "dev_instance_public_ip" {
  value = aws_instance.dev.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.postgresql.endpoint
}