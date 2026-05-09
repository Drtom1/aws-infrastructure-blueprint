# aws-infrastructure-blueprint

Production-style AWS infrastructure provisioned entirely with OpenTofu (Terraform-compatible).
No console clicking — everything is code.

## Architecture

```
                        ┌─────────────────────────────────────────┐
                        │                  AWS VPC                 │
                        │           CIDR: 10.0.0.0/16              │
                        │                                          │
                        │  ┌──────────────┐  ┌──────────────┐     │
  Internet ─── IGW ────►│  │Public Subnet │  │Public Subnet │     │
                        │  │  10.0.1.0/24 │  │  10.0.2.0/24 │     │
                        │  │              │  │              │     │
                        │  │  ┌────────┐  │  │  NAT GW      │     │
                        │  │  │  EC2   │  │  │              │     │
                        │  │  └────────┘  │  └──────────────┘     │
                        │  └──────────────┘          │            │
                        │                            │            │
                        │  ┌──────────────┐  ┌──────────────┐     │
                        │  │Private Subnet│  │Private Subnet│     │
                        │  │  10.0.3.0/24 │  │  10.0.4.0/24 │     │
                        │  │              │  │              │     │
                        │  │  ┌────────┐  │  │              │     │
                        │  │  │  RDS   │  │  │              │     │
                        │  │  └────────┘  │  │              │     │
                        │  └──────────────┘  └──────────────┘     │
                        └─────────────────────────────────────────┘
                                          │
                                     ┌────────┐
                                     │   S3   │
                                     └────────┘
```

## Stack

| Resource | Service | Notes |
|---|---|---|
| Networking | AWS VPC | Multi-AZ, public + private subnets |
| Compute | EC2 (t2.micro) | Free tier, Docker pre-installed |
| Database | RDS MySQL 8.0 | Private subnet, encrypted |
| Storage | S3 | Versioned, encrypted, lifecycle rules |
| IaC | OpenTofu | Modular structure |

## Prerequisites

- [OpenTofu](https://opentofu.org/docs/intro/install/) >= 1.6.0
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configured
- AWS account with IAM credentials

## Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/YOUR_USERNAME/aws-infrastructure-blueprint.git
cd aws-infrastructure-blueprint

# 2. Create your variables file
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# 3. Create the S3 backend bucket (once only)
aws s3api create-bucket --bucket your-state-bucket --region us-east-1
aws s3api put-bucket-versioning \
  --bucket your-state-bucket \
  --versioning-configuration Status=Enabled

# 4. Update backend.tf with your bucket name

# 5. Deploy
chmod +x scripts/deploy.sh
./scripts/deploy.sh apply
```

## Project Structure

```
aws-infrastructure-blueprint/
├── main.tf                  # Root module — calls all child modules
├── variables.tf             # All input variables with validation
├── outputs.tf               # Key outputs (IPs, endpoints, IDs)
├── providers.tf             # AWS provider + version constraints
├── backend.tf               # Remote state config (S3)
├── terraform.tfvars.example # Safe-to-commit variable template
├── .gitignore
├── modules/
│   ├── vpc/                 # VPC, subnets, IGW, NAT, route tables
│   ├── ec2/                 # EC2 instance, security group, IAM role
│   ├── rds/                 # RDS MySQL, subnet group, parameter group
│   └── s3/                  # S3 bucket, encryption, versioning, lifecycle
└── scripts/
    ├── deploy.sh            # Deployment automation
    └── cleanup.sh           # Safe teardown with verification
```

## Cost Warning

All resources use free-tier eligible sizes (`t2.micro`, `db.t3.micro`).
**Always run cleanup when done testing to avoid unexpected charges:**

```bash
./scripts/cleanup.sh
```

## Author

Thomas — Cloud Engineering Portfolio  
[GitHub](https://github.com/YOUR_USERNAME) · [LinkedIn](https://linkedin.com/in/YOUR_PROFILE)
