# VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "dev-vpc-${var.issue_number}"
  }
}

# Public subnet
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-3a"

  tags = {
    Name = "dev-public-subnet-1-${var.issue_number}"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true  
  availability_zone       = "eu-west-3b"

  tags = {
    Name = "dev-public-subnet-2-${var.issue_number}"
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

# Route table associations
resource "aws_route_table_association" "public_subnet_assoc_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rtb.id
}

resource "aws_route_table_association" "public_subnet_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
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
    from_port   = 8080
    to_port     = 8080
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
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
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

resource "aws_db_subnet_group" "rds_subnets" {
  name       = "rds-subnet-${var.issue_number}"
  subnet_ids = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

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
  db_name  = "postgresDevRds${var.issue_number}"

  db_subnet_group_name  = aws_db_subnet_group.rds_subnets.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot   = true

  tags = {
    Name = "postgres_dev_rds_${var.issue_number}"
  }
}

resource "aws_key_pair" "dev_keypair" {
  key_name   = "dev-key-${var.issue_number}"
  public_key = var.dev_env_public_key
}

# EC2 instance for dev
resource "aws_instance" "dev" {
  ami                         = data.aws_ami.ubuntu_ami.id # Ubuntu 22.04
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_subnet_1.id
  vpc_security_group_ids      = [aws_security_group.dev_sg.id]
  associate_public_ip_address = true

  key_name = aws_key_pair.dev_keypair.key_name

  user_data = <<-EOF
              #cloud-config
              packages:
                - git
                - ansible
              runcmd:
                - echo "Running ansible-pull..."
                - ansible-pull -U https://github.com/VerdalJG/n8n-AI-Driven-Env-Provisioning.git -i localhost, issues/26/ansible/playbook.yml
                - mkdir -p /home/ubuntu/.ssh
                - echo "${var.github_runner_key}" >> /home/ubuntu/.ssh/authorized_keys
                - chown -R ubuntu:ubuntu /home/ubuntu/.ssh
                - chmod 600 /home/ubuntu/.ssh/authorized_keys
              EOF

  tags = {
    Name = "dev-ec2-${var.issue_number}"
  }
}
