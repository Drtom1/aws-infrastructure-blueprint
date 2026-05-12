#!/bin/bash
# deploy.sh
# Automates the full deployment workflow
# Usage: ./scripts/deploy.sh [plan|apply|destroy]

set -euo pipefail

# Colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Colour

# Helpers
info()    { echo -e "${BLUE}[INFO]${NC}    $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}    $1"; }
error()   { echo -e "${RED}[ERROR]${NC}   $1"; exit 1; }

# Check Prerequisites
check_prerequisites() {
  info "Checking prerequisites..."

  command -v tofu    >/dev/null 2>&1 || error "OpenTofu not installed. Visit: https://opentofu.org/docs/intro/install/"
  command -v aws     >/dev/null 2>&1 || error "AWS CLI not installed. Visit: https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html"

  # Verify AWS credentials are configured
  aws sts get-caller-identity >/dev/null 2>&1 || error "AWS credentials not configured. Run: aws configure"

  # Verify terraform.tfvars exists
  [ -f "terraform.tfvars" ] || error "terraform.tfvars not found. Copy terraform.tfvars.example and fill in your values."

  success "All prerequisites met."
}

#  Init
run_init() {
  info "Initialising Terraform..."
  tofu init -upgrade
  success "Initialisation complete."
}

# Plan
run_plan() {
  info "Running Terraform plan..."
  tofu plan -out=tfplan
  success "Plan complete. Review the output above before applying."
}

# Apply
run_apply() {
  if [ ! -f "tfplan" ]; then
    warn "No saved plan found. Running plan first..."
    run_plan
  fi

  warn "You are about to apply infrastructure changes to AWS."
  read -rp "Are you sure? Type 'yes' to continue: " confirm
  [ "$confirm" = "yes" ] || error "Deployment cancelled."

  info "Applying Terraform plan..."
  tofu apply tfplan
  rm -f tfplan

  success "Deployment complete!"
  echo ""
  info "Outputs:"
  tofu output
}

#  Destroy
run_destroy() {
  warn "WARNING: This will DESTROY all infrastructure in your AWS account."
  warn "This action is irreversible."
  read -rp "Type 'destroy' to confirm: " confirm
  [ "$confirm" = "destroy" ] || error "Destroy cancelled."

  info "Destroying infrastructure..."
  tofu destroy -auto-approve
  success "All resources destroyed."
}

# Main
main() {
  local command="${1:-help}"

  check_prerequisites

  case "$command" in
    init)    run_init ;;
    plan)    run_init && run_plan ;;
    apply)   run_init && run_apply ;;
    destroy) run_init && run_destroy ;;
    *)
      echo ""
      echo "Usage: ./scripts/deploy.sh [command]"
      echo ""
      echo "Commands:"
      echo "  init     Initialise Terraform and download providers"
      echo "  plan     Preview infrastructure changes"
      echo "  apply    Deploy infrastructure to AWS"
      echo "  destroy  Tear down all infrastructure"
      echo ""
      ;;
  esac
}

main "$@"
