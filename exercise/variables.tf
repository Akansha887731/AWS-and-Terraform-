# First, we define the variables for the VPC ID, username (with the default), and password.

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "db_username" {
  description = "Database administrator username"
  type        = string
  default     = "admin_user"
}

variable "db_password" {
  description = "Database administrator password"
  type        = string
  sensitive   = true
}