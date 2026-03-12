# ==============================================================================
# Security Module — Variables
# ==============================================================================

variable "vpc_id" {
  description = "ID of the VPC where security groups will be created"
  type        = string
}

variable "admin_cidr_blocks" {
  description = "CIDR blocks allowed to SSH into bastion host (restrict to your IP in production)"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = length(var.admin_cidr_blocks) > 0
    error_message = "At least one admin CIDR block must be specified."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
