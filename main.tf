# ─────────────────────────────────────────────
# AWS Infrastructure Blueprint
# Root Module — Orchestrates all child modules
# ─────────────────────────────────────────────

# ── VPC & Networking ──────────────────────────
module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

# ── EC2 Compute ───────────────────────────────
module "ec2" {
  source = "./modules/ec2"

  project_name     = var.project_name
  environment      = var.environment
  instance_type    = var.instance_type
  key_pair_name    = var.key_pair_name
  allowed_ssh_cidr = var.allowed_ssh_cidr
  vpc_id           = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnet_ids[0]
}

# ── RDS Database ──────────────────────────────
module "rds" {
  source = "./modules/rds"

  project_name        = var.project_name
  environment         = var.environment
  db_name             = var.db_name
  db_username         = var.db_username
  db_password         = var.db_password
  db_instance_class   = var.db_instance_class
  allocated_storage   = var.db_allocated_storage
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  ec2_security_group  = module.ec2.security_group_id
}

# ── S3 Storage ────────────────────────────────
module "s3" {
  source = "./modules/s3"

  project_name         = var.project_name
  environment          = var.environment
  enable_versioning    = var.enable_versioning
  force_destroy_bucket = var.force_destroy_bucket
}
