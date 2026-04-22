# ==============================================================================
# Development Environment — Main Configuration
# ==============================================================================
# Cost-optimized environment for development and testing.
# Single NAT gateway, smaller instances, relaxed backup policies.
# ==============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

# --- Local Values ---
locals {
  environment = "dev"
  common_tags = {
    Project     = var.project_name
    Environment = local.environment
    ManagedBy   = "terraform"
    Owner       = var.owner
  }
}

# =============================================================================
# Module: Networking
# =============================================================================
module "networking" {
  source = "../../modules/networking"

  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  single_nat_gateway = true # Cost-effective for dev
  subnet_newbits     = 8

  environment  = local.environment
  project_name = var.project_name
  common_tags  = local.common_tags
}

# =============================================================================
# Module: Security Groups
# =============================================================================
module "security" {
  source = "../../modules/security"

  vpc_id            = module.networking.vpc_id
  admin_cidr_blocks = var.admin_cidr_blocks

  environment  = local.environment
  project_name = var.project_name
  common_tags  = local.common_tags
}

# =============================================================================
# Module: Bastion Host
# =============================================================================
module "bastion" {
  source = "../../modules/bastion"

  instance_type     = "t3.micro"
  subnet_id         = module.networking.public_subnet_ids[0]
  security_group_id = module.security.bastion_security_group_id
  key_name          = var.key_name

  environment  = local.environment
  project_name = var.project_name
  common_tags  = local.common_tags
}

# =============================================================================
# Module: Application Compute
# =============================================================================
module "compute" {
  source = "../../modules/compute"

  instance_type      = "t3.micro"
  instance_count     = 1
  subnet_ids         = module.networking.private_subnet_ids
  security_group_ids = [module.security.application_security_group_id]
  key_name           = var.key_name
  root_volume_size   = 20

  # Database connection details (injected into userdata)
  db_endpoint = module.database.db_address
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  environment  = local.environment
  project_name = var.project_name
  common_tags  = local.common_tags
}

# =============================================================================
# Module: Database (RDS MySQL)
# =============================================================================
module "database" {
  source = "../../modules/database"

  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  max_allocated_storage = 50
  db_name               = var.db_name
  db_username           = var.db_username
  db_password           = var.db_password

  subnet_ids         = module.networking.private_subnet_ids
  security_group_ids = [module.security.database_security_group_id]

  multi_az                     = false # Single-AZ for dev (cost savings)
  backup_retention_period      = 1
  skip_final_snapshot          = true
  deletion_protection          = false
  performance_insights_enabled = false

  environment  = local.environment
  project_name = var.project_name
  common_tags  = local.common_tags
}

# =============================================================================
# Module: IAM
# =============================================================================
module "iam" {
  source = "../../modules/iam"

  iam_users        = var.iam_users
  group_name       = var.iam_group_name
  users_in_group   = var.users_in_group
  independent_user = var.independent_user

  environment  = local.environment
  project_name = var.project_name
  common_tags  = local.common_tags
}
