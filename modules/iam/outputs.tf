# ==============================================================================
# IAM Module — Outputs
# ==============================================================================

output "user_names" {
  description = "List of created IAM user names"
  value       = [for user in aws_iam_user.this : user.name]
}

output "user_arns" {
  description = "Map of user names to their ARNs"
  value       = { for k, user in aws_iam_user.this : k => user.arn }
}

output "group_name" {
  description = "The IAM group name"
  value       = aws_iam_group.this.name
}

output "group_arn" {
  description = "The IAM group ARN"
  value       = aws_iam_group.this.arn
}

output "group_members" {
  description = "Users in the IAM group"
  value       = [for user in var.users_in_group : aws_iam_user.this[user].name]
}

output "independent_user_name" {
  description = "The independent user (not in the group)"
  value       = aws_iam_user.this[var.independent_user].name
}

output "console_login_url" {
  description = "AWS Console sign-in URL for IAM users"
  value       = "https://${data.aws_caller_identity.current.account_id}.signin.aws.amazon.com/console"
}

output "user_credentials" {
  description = "IAM user credentials (access keys and initial passwords)"
  value = {
    for user_name, user in aws_iam_user.this : user_name => {
      username          = user.name
      access_key_id     = aws_iam_access_key.this[user_name].id
      secret_access_key = aws_iam_access_key.this[user_name].secret
      console_password  = aws_iam_user_login_profile.this[user_name].password
      console_login_url = "https://${data.aws_caller_identity.current.account_id}.signin.aws.amazon.com/console"
    }
  }
  sensitive = true
}
