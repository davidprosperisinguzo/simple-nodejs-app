variable "aws_region" {
  description = "AWS region in which to create the infrastructure."
  type        = string
  default     = "eu-west-2"
}

variable "name_prefix" {
  description = "Prefix used for resource names."
  type        = string
  default     = "nodejs-cicd"
}

variable "project_tag" {
  description = "Value assigned to the Project tag on taggable resources."
  type        = string
  default     = "nodejs-cicd-assignment"
}

variable "app_port" {
  description = "Public TCP port used by the Node.js application."
  type        = number
  default     = 3000
}

variable "instance_type" {
  description = "EC2 instance type. t3.micro is free-tier eligible in eu-west-2."
  type        = string
  default     = "t3.micro"
}

variable "ssh_private_key_path" {
  description = "Local path for the generated EC2 private key."
  type        = string
  default     = "~/.ssh/nodejs-cicd-key.pem"
}
