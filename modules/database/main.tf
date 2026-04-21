# ==============================================================================
# Database Module — RDS MySQL with Multi-AZ Support
# ==============================================================================
# Provisions a managed MySQL RDS instance with configurable Multi-AZ,
# encryption at rest, automated backups, and private subnet isolation.
# ==============================================================================

# --- DB Subnet Group (RDS requires subnets in 2+ AZs) ---
resource "aws_db_subnet_group" "this" {
  name        = "${var.project_name}-db-subnet-group-${var.environment}"
  description = "Database subnet group for ${var.environment} environment"
  subnet_ids  = var.subnet_ids

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-db-subnet-group-${var.environment}"
  })
}

# --- RDS MySQL Instance ---
resource "aws_db_instance" "this" {
  identifier = "${var.project_name}-mysql-${var.environment}"

  # Engine configuration
  engine         = "mysql"
  engine_version = var.engine_version
  instance_class = var.instance_class

  # Storage
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  # Database configuration
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # Networking
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = var.security_group_ids
  publicly_accessible    = false

  # High availability
  multi_az = var.multi_az

  # Backups
  backup_retention_period = var.backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  # Snapshot management
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project_name}-mysql-final-${var.environment}"

  # Deletion protection (enabled in prod)
  deletion_protection = var.deletion_protection

  # Performance & monitoring
  performance_insights_enabled = var.performance_insights_enabled

  # Parameter group
  parameter_group_name = aws_db_parameter_group.this.name

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-mysql-${var.environment}"
    Tier = "database"
  })
}

# --- Custom Parameter Group ---
resource "aws_db_parameter_group" "this" {
  name        = "${var.project_name}-mysql-params-${var.environment}"
  family      = "mysql8.0"
  description = "Custom parameter group for ${var.environment}"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-mysql-params-${var.environment}"
  })
}
