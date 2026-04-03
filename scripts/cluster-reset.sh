#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Deleting minikube cluster..."
minikube delete

echo "==> Recreating cluster..."
"${SCRIPT_DIR}/cluster-start.sh"
