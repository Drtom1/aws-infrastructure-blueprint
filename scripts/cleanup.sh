#!/bin/bash
# ─────────────────────────────────────────────
# cleanup.sh
# Safely destroys all resources and confirms
# nothing is left running that could incur cost
# Usage: ./scripts/cleanup.sh
# ─────────────────────────────────────────────

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC}    $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}    $1"; }
error()   { echo -e "${RED}[ERROR]${NC}   $1"; exit 1; }

REGION="${AWS_REGION:-us-east-1}"
PROJECT="${PROJECT_NAME:-blueprint}"

echo ""
warn "========================================"
warn "  INFRASTRUCTURE CLEANUP"
warn "========================================"
echo ""
warn "This script will destroy all resources tagged with Project=${PROJECT}"
warn "Region: ${REGION}"
echo ""

read -rp "Type 'confirm' to proceed: " confirm
[ "$confirm" = "confirm" ] || error "Cleanup cancelled."

# ── Destroy via Terraform first ───────────────
info "Running tofu destroy..."
tofu destroy -auto-approve

# ── Verify no EC2 instances remain ────────────
info "Verifying EC2 instances are terminated..."
INSTANCES=$(aws ec2 describe-instances \
  --region "$REGION" \
  --filters "Name=tag:Project,Values=${PROJECT}" "Name=instance-state-name,Values=running,stopped,pending" \
  --query "Reservations[*].Instances[*].InstanceId" \
  --output text)

if [ -n "$INSTANCES" ]; then
  warn "Found remaining EC2 instances: $INSTANCES"
  warn "Terminating..."
  aws ec2 terminate-instances --region "$REGION" --instance-ids $INSTANCES
else
  success "No EC2 instances remaining."
fi

# ── Verify no RDS instances remain ────────────
info "Verifying RDS instances are deleted..."
DBS=$(aws rds describe-db-instances \
  --region "$REGION" \
  --query "DBInstances[?TagList[?Key=='Project' && Value=='${PROJECT}']].DBInstanceIdentifier" \
  --output text)

if [ -n "$DBS" ]; then
  warn "Found remaining RDS instances: $DBS"
  warn "Please delete manually from the AWS console."
else
  success "No RDS instances remaining."
fi

echo ""
success "Cleanup complete. No billable resources should remain."
info "Check your AWS Billing dashboard to confirm: https://console.aws.amazon.com/billing"
