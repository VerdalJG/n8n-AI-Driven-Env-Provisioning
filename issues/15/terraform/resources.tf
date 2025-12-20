# VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "dev-vpc-${var.issue_number}"
  }
}

# Public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "dev-public-subnet-${var.issue_number}"
  }
}

# Internet gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "dev-igw-${var.issue_number}"
  }
}

# Route table
resource "aws_route_table" "public_rtb" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "dev-public-rtb-${var.issue_number}"
  }
}

# Route table association
resource "aws_route_table_association" "public_subnet_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rtb.id
}

# Security group for dev EC2
resource "aws_security_group" "dev_sg" {
  name   = "dev-sg-${var.issue_number}"
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH from anywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dev-sg-${var.issue_number}"
  }
}

# Security group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg-${var.issue_number}"
  description = "Allow access from dev instance only"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.dev_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg-${var.issue_number}"
  }
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-${var.issue_number}"
  subnet_ids = [aws_subnet.public_subnet.id]

  tags = {
    Name = "rds-subnet-${var.issue_number}"
  }
}

# RDS instance in public subnet
resource "aws_db_instance" "postgresql" {
  allocated_storage    = 10
  engine               = "postgres"
  engine_version       = "16.11"
  instance_class       = "db.t3.micro"
  storage_type         = "gp2"
  publicly_accessible  = true

  username = var.db_username
  password = var.db_password
  db_name  = "postgres-rds-${var.issue_number}"

  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  skip_final_snapshot = true

  tags = {
    Name = "dev-rds-${var.issue_number}"
  }
}

resource "aws_key_pair" "dev_keypair" {
  key_name   = "dev-key-${var.issue_number}"
  public_key = var.dev_env_public_key
}

# EC2 instance for dev