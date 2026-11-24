data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_caller_identity" "current" {}

data "aws_iam_openid_connect_provider" "github" {
  arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
}

resource "aws_ecr_repository" "app" {
  name                 = "${var.name_prefix}-app"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  tags = {
    Name = "${var.name_prefix}-app"
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep only the most recent five images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = {
        type = "expire"
      }
    }]
  })
}

resource "tls_private_key" "ec2" {
  algorithm = "ED25519"
}

resource "aws_key_pair" "ec2" {
  key_name   = "${var.name_prefix}-key"
  public_key = tls_private_key.ec2.public_key_openssh

  tags = {
    Name = "${var.name_prefix}-key"
  }
}

resource "local_sensitive_file" "ec2_private_key" {
  filename        = pathexpand(var.ssh_private_key_path)
  content         = tls_private_key.ec2.private_key_openssh
  file_permission = "0400"

  depends_on = [aws_key_pair.ec2]
}

resource "aws_security_group" "app" {
  name        = "${var.name_prefix}-sg"
  description = "SSH and Node.js application access"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "${var.name_prefix}-sg"
  }

  ingress {
    description = "SSH access; publicly open for changing GitHub-hosted runner IPs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Node.js application"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "ec2" {
  name = "${var.name_prefix}-ec2-ecr-read-role"

  tags = {
    Name = "${var.name_prefix}-ec2-ecr-read-role"
  }

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_ecr_readonly" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.name_prefix}-ec2-profile"
  role = aws_iam_role.ec2.name

  tags = {
    Name = "${var.name_prefix}-ec2-profile"
  }
}

resource "aws_instance" "app" {
  ami                         = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.ec2.key_name
  vpc_security_group_ids      = [aws_security_group.app.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  user_data                   = file("${path.module}/user_data.sh")
  user_data_replace_on_change = true

  tags = {
    Name = "${var.name_prefix}-instance"
  }
}

resource "aws_iam_role" "github_actions" {
  name = "nodejs-cicd-github-actions"

  tags = {
    Name = "nodejs-cicd-github-actions"
  }

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = data.aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = "repo:davidprosperisinguzo/simple-nodejs-app:ref:refs/heads/master"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "github_actions_ecr" {
  name = "${var.name_prefix}-ecr-push-pull"
  role = aws_iam_role.github_actions.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ECRAuthorization"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid    = "RepositoryPushPull"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
        Resource = aws_ecr_repository.app.arn
      }
    ]
  })
}
