output "aws_region" {
  description = "AWS region used for this deployment."
  value       = var.aws_region
}

output "ecr_repository_name" {
  description = "ECR repository name."
  value       = aws_ecr_repository.app.name
}

output "ecr_repository_url" {
  description = "ECR repository URL."
  value       = aws_ecr_repository.app.repository_url
}

output "app_port" {
  description = "Public application port."
  value       = var.app_port
}

output "instance_id" {
  description = "EC2 instance ID."
  value       = aws_instance.app.id
}

output "instance_public_ip" {
  description = "Public IPv4 address currently assigned to the EC2 instance."
  value       = aws_instance.app.public_ip
}

output "ec2_user" {
  description = "Default SSH user for the Ubuntu AMI."
  value       = "ubuntu"
}

output "ssh_private_key_path" {
  description = "Path to the generated private key on the machine running Terraform."
  value       = pathexpand(var.ssh_private_key_path)
}

output "github_actions_role_arn" {
  description = "IAM role ARN assumed by GitHub Actions via OIDC."
  value       = aws_iam_role.github_actions.arn
}
