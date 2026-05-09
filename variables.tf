# ─────────────────────────────────────────────
# Global Variables
# ─────────────────────────────────────────────

variable "aws_region" {
  description = "AWS region to deploy all resources"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "Must be a valid AWS region format e.g. us-east-1."
  }
}

variable "project_name" {
  description = "Name prefix applied to all resources"
  type        = string
  default     = "blueprint"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "owner" {
  description = "Owner tag applied to all resources"
  type        = string
  default     = "thomas"
}

# ─────────────────────────────────────────────
# Networking Variables
# ─────────────────────────────────────────────

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "availability_zones" {
  description = "Availability zones to deploy subnets into"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# ─────────────────────────────────────────────
# EC2 Variables
# ─────────────────────────────────────────────

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro" # Free tier eligible
}

variable "key_pair_name" {
  description = "Name of existing AWS key pair for SSH access"
  type        = string
  default     = ""
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH into EC2 (restrict to your IP in production)"
  type        = string
  default     = "0.0.0.0/0"
}

# ─────────────────────────────────────────────
# RDS Variables
# ─────────────────────────────────────────────

variable "db_name" {
  description = "Name of the database to create"
  type        = string
  default     = "blueprintdb"
}

variable "db_username" {
  description = "Master username for RDS instance"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "db_password" {
  description = "Master password for RDS instance"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro" # Free tier eligible
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB for RDS"
  type        = number
  default     = 20
}

# ─────────────────────────────────────────────
# S3 Variables
# ─────────────────────────────────────────────

variable "enable_versioning" {
  description = "Enable versioning on the S3 bucket"
  type        = bool
  default     = true
}

variable "force_destroy_bucket" {
  description = "Allow bucket to be destroyed even if it contains objects"
  type        = bool
  default     = false
}
