# ==============================================================================
# Production Environment — Outputs
# ==============================================================================

output "environment" {
  description = "Environment name"
  value       = local.environment
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.networking.private_subnet_ids
}

output "total_subnet_count" {
  description = "Total number of subnets"
  value       = module.networking.total_subnet_count
}

output "nat_gateway_public_ips" {
  description = "NAT Gateway Elastic IPs (one per AZ in prod)"
  value       = module.networking.nat_gateway_public_ips
}

output "bastion_public_ip" {
  description = "Bastion host public IP"
  value       = module.bastion.public_ip
}

output "bastion_ssh_command" {
  description = "SSH command to connect to bastion"
  value       = module.bastion.ssh_command
}

output "app_instance_ids" {
  description = "Application EC2 instance IDs"
  value       = module.compute.instance_ids
}

output "app_private_ips" {
  description = "Application instance private IPs"
  value       = module.compute.instance_private_ips
}

output "app_instance_details" {
  description = "Detailed information for each application instance"
  value       = module.compute.instance_details
}

output "db_endpoint" {
  description = "RDS MySQL endpoint"
  value       = module.database.db_endpoint
}

output "db_arn" {
  description = "RDS instance ARN"
  value       = module.database.db_arn
}

output "db_connection_command" {
  description = "MySQL connection command (run from bastion/app server)"
  value       = module.database.mysql_connection_command
}

output "iam_users" {
  description = "Created IAM users"
  value       = module.iam.user_names
}

output "iam_group" {
  description = "IAM group name"
  value       = module.iam.group_name
}

output "iam_console_login_url" {
  description = "AWS Console login URL for IAM users"
  value       = module.iam.console_login_url
}

output "iam_user_credentials" {
  description = "IAM user credentials"
  value       = module.iam.user_credentials
  sensitive   = true
}
