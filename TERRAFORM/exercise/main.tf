# This is where the magic happens. We use the aws_subnets data source to fetch the hidden subnet IDs dynamically, bundle them into an aws_db_subnet_group, and then spin up the aws_db_instance.

# 1. Fetch the subnet IDs dynamically using the VPC ID
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

# 2. Create the DB Subnet Group using the fetched subnet IDs
resource "aws_db_subnet_group" "default" {
  name       = "my-rds-subnet-group"
  subnet_ids = data.aws_subnets.private.ids
}

# 3. Create the MySQL RDS Database Instance
resource "aws_db_instance" "default" {
  engine                 = "mysql"
  instance_class         = "db.t3.micro"
  allocated_storage      = 10
  port                   = 3306
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.default.name
  skip_final_snapshot    = true # Good practice for exercises so you can destroy it easily
}