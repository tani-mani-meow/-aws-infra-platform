# ==============================================================================
# Database Module — Outputs
# ==============================================================================

output "db_instance_id" {
  description = "The RDS instance identifier"
  value       = aws_db_instance.this.id
}

output "db_endpoint" {
  description = "The connection endpoint (host:port)"
  value       = aws_db_instance.this.endpoint
}

output "db_address" {
  description = "The hostname of the RDS instance"
  value       = aws_db_instance.this.address
}

output "db_port" {
  description = "The database port"
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "The name of the database"
  value       = aws_db_instance.this.db_name
}

output "db_arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.this.arn
}

output "db_subnet_group_name" {
  description = "The name of the DB subnet group"
  value       = aws_db_subnet_group.this.name
}

output "mysql_connection_command" {
  description = "MySQL command to connect from an EC2 instance in the same VPC"
  value       = "mysql -h ${aws_db_instance.this.address} -u ${var.db_username} -p ${var.db_name}"
}
