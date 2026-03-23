# ==============================================================================
# Bastion Module — Outputs
# ==============================================================================

output "instance_id" {
  description = "Instance ID of the bastion host"
  value       = aws_instance.bastion.id
}

output "public_ip" {
  description = "Public IP address of the bastion host"
  value       = aws_instance.bastion.public_ip
}

output "public_dns" {
  description = "Public DNS name of the bastion host"
  value       = aws_instance.bastion.public_dns
}

output "ssh_command" {
  description = "SSH command to connect to the bastion host"
  value       = "ssh -i ${var.key_name}.pem ubuntu@${aws_instance.bastion.public_ip}"
}

output "ami_id" {
  description = "AMI ID used for the bastion host"
  value       = data.aws_ami.ubuntu.id
}
