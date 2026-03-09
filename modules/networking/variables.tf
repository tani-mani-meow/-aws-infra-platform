# ==============================================================================
# Networking Module — Variables
# ==============================================================================

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid CIDR block (e.g., 10.0.0.0/16)."
  }
}

variable "availability_zones" {
  description = "List of availability zones to deploy subnets into"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones are required for high availability."
  }
}

variable "subnet_newbits" {
  description = "Number of additional bits to extend the VPC CIDR for subnet calculation (e.g., 8 for /16 → /24)"
  type        = number
  default     = 8
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway (cost-effective for dev/staging) vs one per AZ (HA for prod)"
  type        = bool
  default     = true
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
