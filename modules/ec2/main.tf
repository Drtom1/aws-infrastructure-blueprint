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
    Name        = "${local.name_prefix}-ec2"
    Environment = var.environment
    ManagedBy   = "Terraform"
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

# Least privilege policy for CloudWatch Logs and monitoring
resource "aws_iam_role_policy" "monitoring" {
  name = "${local.name_prefix}-ec2-monitoring-policy"
  role = aws_iam_role.ec2_ssm.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
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

  # Enhanced monitoring
  monitoring                  = var.enable_monitoring
  associate_public_ip_address = true

  # Security: Enforce IMDSv2
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 only
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  # Harden root volume with gp3
  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    encrypted             = true
    delete_on_termination = true
    tags = {
      Name = "${local.name_prefix}-root-volume"
    }
  }

  # Enable EBS optimization for better performance
  ebs_optimized = var.enable_ebs_optimization

  # User data with CloudWatch agent installation
  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e
    yum update -y
    yum install -y htop curl wget git amazon-cloudwatch-agent
    amazon-linux-extras install -y docker
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user
    
    # Log startup to CloudWatch
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
      -a fetch-config \
      -m ec2 \
      -s
    echo "EC2 instance initialization completed" | logger -t ec2-init
  EOF
  )

  tags = local.common_tags

  lifecycle {
    ignore_changes = [ami]
  }
}

# CloudWatch alarm for EC2 instance state check
resource "aws_cloudwatch_metric_alarm" "instance_state_check" {
  count               = var.enable_auto_recovery ? 1 : 0
  alarm_name          = "${local.name_prefix}-instance-state-check"
  alarm_description   = "Alert when EC2 instance fails system status checks"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed_System"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.main.id
  }

  alarm_actions = var.alarm_email != "" ? [aws_sns_topic.alarms[0].arn] : []
  tags          = local.common_tags
}

# CloudWatch alarm for CPU utilization
resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  alarm_name          = "${local.name_prefix}-cpu-utilization"
  alarm_description   = "Alert when CPU utilization exceeds ${var.cpu_threshold}%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.main.id
  }

  alarm_actions = var.alarm_email != "" ? [aws_sns_topic.alarms[0].arn] : []
  tags          = local.common_tags
}

# SNS Topic for alarms (only if email provided)
resource "aws_sns_topic" "alarms" {
  count = var.alarm_email != "" ? 1 : 0
  name  = "${local.name_prefix}-ec2-alarms"
  tags  = local.common_tags
}

resource "aws_sns_topic_subscription" "alarm_email" {
  count     = var.alarm_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alarms[0].arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# CloudWatch Log Group for EC2 application logs
resource "aws_cloudwatch_log_group" "ec2" {
  name              = "/aws/ec2/${local.name_prefix}"
  retention_in_days = 7

  tags = local.common_tags
}