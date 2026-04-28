terraform {
  backend "s3" {
    bucket         = "aws-infra-platform-tfstate"
    key            = "environments/prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "aws-infra-platform-tflock"
    encrypt        = true
  }
}
