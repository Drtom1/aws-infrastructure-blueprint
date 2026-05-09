# ─────────────────────────────────────────────
# Remote State Backend
#
# IMPORTANT: Before running `tofu init`:
#   1. Create the S3 bucket manually in AWS console
#      or via AWS CLI:
#      aws s3api create-bucket \
#        --bucket <your-state-bucket-name> \
#        --region us-east-1
#
#   2. Enable versioning on the bucket:
#      aws s3api put-bucket-versioning \
#        --bucket <your-state-bucket-name> \
#        --versioning-configuration Status=Enabled
#
#   3. Replace the bucket name below with yours
# ─────────────────────────────────────────────

terraform {
  backend "s3" {
    bucket  = "thomas-blueprint-terraform-state"
    key     = "dev/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
