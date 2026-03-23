# ==============================================================================
# Bastion Module — Hardened Jump Host in Public Subnet
# ==============================================================================
# Provides secure SSH access to private resources. The bastion host is the
# only entry point into the private network — all admin access flows through it.
# ==============================================================================

# --- Latest Ubuntu 22.04 AMI (auto-discovered) ---
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# --- Bastion Host ---
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_name

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_tokens   = "required" # IMDSv2 enforced (security best practice)
    http_endpoint = "enabled"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-bastion-${var.environment}"
    Role = "bastion"
  })
}
