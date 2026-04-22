# ==============================================================================
# Development Environment — Remote State Backend
# ==============================================================================
# Uses S3 for state storage and DynamoDB for state locking.
# Run scripts/bootstrap-backend.sh to create these resources first.
# ==============================================================================

terraform {
  backend "s3" {
    bucket         = "aws-infra-platform-tfstate"
    key            = "environments/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "aws-infra-platform-tflock"
    encrypt        = true
  }
}
