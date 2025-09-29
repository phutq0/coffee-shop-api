#!/usr/bin/env bash
set -euo pipefail

ENV_DIR=${1:-"environments/dev"}

export AWS_REGION=${AWS_REGION:-us-east-1}
export TF_STATE_BUCKET=${TF_STATE_BUCKET:-your-tfstate-bucket}
export TF_STATE_LOCK_TABLE=${TF_STATE_LOCK_TABLE:-your-tfstate-locks}

cd "$(dirname "$0")/.." || exit 1

echo "Initializing Terraform in $ENV_DIR"
(cd "$ENV_DIR" && terraform init)
