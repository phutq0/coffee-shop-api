#!/usr/bin/env bash
set -euo pipefail

ENV_DIR=${1:-"environments/dev"}

cd "$(dirname "$0")/.." || exit 1

terraform -chdir="$ENV_DIR" destroy -auto-approve
