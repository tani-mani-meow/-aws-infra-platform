# ==============================================================================
# IAM Module — Variables
# ==============================================================================

variable "iam_users" {
  description = "List of IAM usernames to create"
  type        = list(string)

  validation {
    condition     = length(var.iam_users) >= 1
    error_message = "At least one IAM user must be specified."
  }
}

variable "group_name" {
  description = "Name of the IAM group"
  type        = string
  default     = "developers"
}

variable "users_in_group" {
  description = "List of users to add to the IAM group (must be a subset of iam_users)"
  type        = list(string)
}

variable "independent_user" {
  description = "Username that remains outside the group with a direct policy"
  type        = string
}

variable "group_policy_name" {
  description = "Name for the group-level policy"
  type        = string
  default     = "group-s3-read-policy"
}

variable "user_policy_name" {
  description = "Name for the independent user's policy"
  type        = string
  default     = "user-ec2-read-policy"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource scoping and naming"
  type        = string
}

variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
