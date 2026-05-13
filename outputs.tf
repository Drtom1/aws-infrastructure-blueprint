
# Root Outputs

# VPC Outputs
output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

# EC2 Outputs
output "ec2_instance_id" {
  description = "ID of the EC2 instance"
  value       = module.ec2.instance_id
}

output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = module.ec2.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = module.ec2.public_dns
}

# RDS Outputs
output "rds_endpoint" {
  description = "RDS instance connection endpoint"
  value       = module.rds.db_endpoint
}

output "rds_port" {
  description = "RDS instance port"
  value       = module.rds.db_port
}

# S3 Outputs
output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.s3.bucket_name
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.s3.bucket_arn
}
