output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.main.id
}

output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.main.public_ip
}

output "public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.main.public_dns
}

output "security_group_id" {
  description = "ID of the EC2 security group"
  value       = aws_security_group.ec2.id
}

output "iam_role_arn" {
  description = "ARN of the EC2 IAM role"
  value       = aws_iam_role.ec2_ssm.arn
}

output "log_group_name" {
  description = "CloudWatch Log Group name for EC2 instance"
  value       = aws_cloudwatch_log_group.ec2.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.ec2.arn
}

output "sns_topic_arn" {
  description = "ARN of SNS topic for CloudWatch alarms"
  value       = try(aws_sns_topic.alarms[0].arn, null)
}
