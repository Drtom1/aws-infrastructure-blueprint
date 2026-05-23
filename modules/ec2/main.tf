# ─────────────────────────────────────────────
# Module: EC2
# Creates:
#   - Security group with SSH + HTTP access
#   - EC2 instance in the public subnet
#   - IAM role with SSM access (so you can
#     connect without a key pair if needed)

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = {
    Name = "${local.name_prefix}-ec2"
  }
}

# Fetch Latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group
resource "aws_security_group" "ec2" {
  name        = "${local.name_prefix}-ec2-sg"
  description = "Security group for EC2 instance"
  vpc_id      = var.vpc_id

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # HTTP and HTTPS access (combined rule)
  ingress {
    description = "Web traffic (HTTP/HTTPS)"
    from_port   = 80
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Component = "SecurityGroup" })
}

# IAM Role for SSM (Session Manager)
resource "aws_iam_role" "ec2_ssm" {
  name = "${local.name_prefix}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, { Component = "IAMRole" })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${local.name_prefix}-ec2-profile"
  role = aws_iam_role.ec2_ssm.name
}

# EC2 Instance
resource "aws_instance" "main" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name
  key_name               = var.key_pair_name != "" ? var.key_pair_name : null

  # Harden root volume
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    delete_on_termination = true
  }

  # Bootstrap script installs common tools on launch
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y htop curl wget git
    amazon-linux-extras install -y docker
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user
  EOF

  tags = local.common_tags

  lifecycle {
    # Prevent accidental instance replacement when AMI updates
    ignore_changes = [ami]
  }
}
#resource "aws_acm_certificate" "ec2" {
 