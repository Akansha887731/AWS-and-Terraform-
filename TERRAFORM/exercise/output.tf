# Here is where we extract the values you want to return after the database is successfully created. Note that Terraform requires the password output to be marked as sensitive.

output "database_hostname" {
  description = "The hostname of the RDS instance"
  value       = aws_db_instance.default.address
}

output "database_port" {
  description = "The port the database is listening on"
  value       = aws_db_instance.default.port
}

output "database_username" {
  description = "The master username for the database"
  value       = aws_db_instance.default.username
}

output "database_password" {
  description = "The master password for the database"
  value       = aws_db_instance.default.password
  sensitive   = true
}