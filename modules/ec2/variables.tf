variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_pair_name" {
  description = "Name of existing AWS key pair (leave empty to use SSM only)"
  type        = string
  default     = ""
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into the instance"
  type        = string
  default     = "0.0.0.0/0"
}

variable "vpc_id" {
  description = "VPC ID to launch the instance into"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID to launch the instance into"
  type        = string
}

variable "enable_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "enable_auto_recovery" {
  description = "Enable EC2 auto recovery on instance failure"
  type        = bool
  default     = true
}

variable "root_volume_size" {
  description = "Size of root EBS volume in GB"
  type        = number
  default     = 20
}

variable "enable_ebs_optimization" {
  description = "Enable EBS optimization for better performance"
  type        = bool
  default     = true
}

variable "cpu_threshold" {
  description = "CPU utilization threshold for CloudWatch alarm"
  type        = number
  default     = 80
}

variable "alarm_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
  default     = ""
}
