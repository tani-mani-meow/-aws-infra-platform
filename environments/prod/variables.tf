# ==============================================================================
# Production Environment — Variables
# ==============================================================================

variable "project_name" {
  description = "Project name used across all resources"
  type        = string
  default     = "aws-infra-platform"
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "owner" {
  description = "Owner tag for resource identification"
  type        = string
  default     = "devops-team"
}

variable "vpc_cidr" {
  description = "CIDR block for the production VPC"
  type        = string
  default     = "172.16.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones for production (3 AZs for maximum HA)"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "admin_cidr_blocks" {
  description = "CIDR blocks allowed SSH access to bastion (MUST restrict in production)"
  type        = list(string)
  # No default — forces explicit configuration in prod
}

variable "key_name" {
  description = "Name of the EC2 key pair for SSH access"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "iam_users" {
  description = "List of IAM users to create"
  type        = list(string)
  default     = ["prod-user-1", "prod-user-2", "prod-user-3"]
}

variable "iam_group_name" {
  description = "IAM group name"
  type        = string
  default     = "prod-team"
}

variable "users_in_group" {
  description = "Users to add to the IAM group"
  type        = list(string)
  default     = ["prod-user-1", "prod-user-2"]
}

variable "independent_user" {
  description = "User that remains outside the group"
  type        = string
  default     = "prod-user-3"
}
