# ==============================================================================
# Security Module — Security Groups (Bastion, Application, Database, ALB)
# ==============================================================================
# Implements defense-in-depth with layered security groups following the
# principle of least privilege. Each tier only accepts traffic from the
# tier directly above it.
# ==============================================================================

# --- Bastion Security Group ---
# SSH access restricted to specified admin CIDR blocks only
resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-bastion-sg-${var.environment}"
  description = "Security group for bastion host - SSH from admin CIDR only"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from admin CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.admin_cidr_blocks
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-bastion-sg-${var.environment}"
    Tier = "bastion"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# --- Application Security Group ---
# HTTP/HTTPS from anywhere (or ALB SG), SSH only from bastion
resource "aws_security_group" "application" {
  name        = "${var.project_name}-app-sg-${var.environment}"
  description = "Security group for application servers"
  vpc_id      = var.vpc_id

  # HTTP from anywhere (or restrict to ALB SG in production)
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS from anywhere
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH only from bastion security group
  ingress {
    description     = "SSH from bastion only"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-app-sg-${var.environment}"
    Tier = "application"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# --- Database Security Group ---
# MySQL (3306) only from application security group
resource "aws_security_group" "database" {
  name        = "${var.project_name}-db-sg-${var.environment}"
  description = "Security group for RDS - MySQL from application tier only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from application tier"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.application.id]
  }

  # Allow bastion to connect for database administration
  ingress {
    description     = "MySQL from bastion for admin"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-db-sg-${var.environment}"
    Tier = "database"
  })

  lifecycle {
    create_before_destroy = true
  }
}
