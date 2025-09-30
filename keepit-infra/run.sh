#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Config / Defaults
# -----------------------------
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$REPO_ROOT/bootstrap"
ROOT_DIR="$REPO_ROOT"
ENV="${1:-dev}"         # Usage: ./run.sh [dev|staging|prod] [apply|plan|destroy]
ACTION="${2:-apply}"    # default: apply
TFVARS_FILE="$REPO_ROOT/env/${ENV}.tfvars"

# State key per environment (keeps each env isolated in the bucket)
STATE_KEY="${ENV}/terraform.tfstate"

# -----------------------------
# Preflight checks
# -----------------------------
need() { command -v "$1" >/dev/null 2>&1 || { echo "ERROR: '$1' is required but not installed."; exit 1; }; }

need terraform
need aws
need jq

if [[ ! -f "$TFVARS_FILE" ]]; then
  echo "ERROR: tfvars file not found: $TFVARS_FILE"
  echo "Create it (you listed: env/dev.tfvars, env/staging.tfvars, env/prod.tfvars)."
  exit 1
fi

# HCL syntactic pitfall guard (common issue you hit earlier):
# Ensure variable blocks use newlines between attributes. Example:
# variable "kms_key_arn" {
#   type    = string
#   default = ""
# }
# One-line 'type = string default = ""' will error in HCL.

# -----------------------------
# Step 1: Bootstrap (creates S3 bucket, DynamoDB lock table, optional KMS)
# -----------------------------
echo "==> [${ENV}] Bootstrapping remote state (S3/DynamoDB/KMS) ..."
terraform -chdir="$BOOTSTRAP_DIR" init -upgrade

# Choose action for bootstrap: always ensure infra exists before main.
case "$ACTION" in
  destroy)
    echo "==> Destroying bootstrap resources (this will remove state backend infra!)"
    terraform -chdir="$BOOTSTRAP_DIR" destroy -auto-approve -var-file="$TFVARS_FILE"
    echo "Bootstrap destroyed. Skipping main stack."
    exit 0
    ;;
  plan)
    terraform -chdir="$BOOTSTRAP_DIR" plan -var-file="$TFVARS_FILE"
    ;;
  apply|*)
    terraform -chdir="$BOOTSTRAP_DIR" apply -auto-approve -var-file="$TFVARS_FILE"
    ;;
esac

# -----------------------------
# Step 2: Read bootstrap outputs
# Expect these output names in bootstrap/outputs.tf:
# - tf_state_bucket
# - tf_lock_table
# - aws_region
# (optional) kms_key_arn
# -----------------------------
echo "==> Reading bootstrap outputs ..."
BOOTSTRAP_OUT_JSON="$(terraform -chdir="$BOOTSTRAP_DIR" output -json)"

TF_STATE_BUCKET="$(jq -r '.tf_state_bucket.value' <<<"$BOOTSTRAP_OUT_JSON")"
TF_LOCK_TABLE="$(jq -r '.tf_lock_table.value' <<<"$BOOTSTRAP_OUT_JSON")"
AWS_REGION="$(jq -r '.aws_region.value' <<<"$BOOTSTRAP_OUT_JSON" 2>/dev/null || echo "")"
KMS_KEY_ARN="$(jq -r '.kms_key_arn.value // empty' <<<"$BOOTSTRAP_OUT_JSON" 2>/dev/null || echo "")"

if [[ -z "$TF_STATE_BUCKET" || -z "$TF_LOCK_TABLE" ]]; then
  echo "ERROR: Missing required bootstrap outputs. Ensure outputs.tf exports tf_state_bucket and tf_lock_table."
  exit 1
fi

# Fallback region if not output (uses current AWS CLI profile/region)
if [[ -z "$AWS_REGION" ]]; then
  AWS_REGION="$(aws configure get region || echo "us-east-1")"
fi

# -----------------------------
# Step 3: Initialize root (wire backend to created bucket/table)
# -----------------------------
echo "==> [${ENV}] Initializing root with backend: bucket=${TF_STATE_BUCKET}, table=${TF_LOCK_TABLE}, region=${AWS_REGION}, key=${STATE_KEY}"
terraform -chdir="$ROOT_DIR" init -upgrade \
  -backend-config="bucket=${TF_STATE_BUCKET}" \
  -backend-config="dynamodb_table=${TF_LOCK_TABLE}" \
  -backend-config="region=${AWS_REGION}" \
  -backend-config="key=${STATE_KEY}"

# Create/select workspace for env
if terraform -chdir="$ROOT_DIR" workspace list | grep -qE "^\*?\\s*${ENV}\$"; then
  terraform -chdir="$ROOT_DIR" workspace select "${ENV}" >/dev/null
else
  terraform -chdir="$ROOT_DIR" workspace new "${ENV}" >/dev/null
fi

# -----------------------------
# Step 4: Plan/Apply main stack (root calls modules in dependency order)
# NOTE: Let Terraform's DAG handle module order via inputs/outputs.
# If you must force-sequence, you can run targeted applies per module,
# but it's usually better to model dependencies between modules.
# -----------------------------
echo "==> [${ENV}] ${ACTION^} main stack with ${TFVARS_FILE} ..."
case "$ACTION" in
  plan)
    terraform -chdir="$ROOT_DIR" plan -var-file="$TFVARS_FILE"
    ;;
  apply|*)
    terraform -chdir="$ROOT_DIR" apply -auto-approve -var-file="$TFVARS_FILE"
    ;;
  destroy)
    terraform -chdir="$ROOT_DIR" destroy -auto-approve -var-file="$TFVARS_FILE"
    ;;
esac

echo "==> Done."
echo "Workspace: ${ENV}"
echo "State: s3://${TF_STATE_BUCKET}/${STATE_KEY} (locks in ${TF_LOCK_TABLE})"
