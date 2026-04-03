#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="$(basename "${SCRIPT_DIR}")"

echo "==> Adding bitnami Helm repo..."
helm repo add bitnami https://charts.bitnami.com/bitnami 2>/dev/null || true
helm repo update

echo "==> Installing/upgrading ${APP_NAME}..."
helm upgrade --install "${APP_NAME}" \
  bitnami/nginx \
  --namespace apps \
  --create-namespace \
  --values "${SCRIPT_DIR}/values.yaml" \
  --wait \
  --timeout 5m

echo ""
echo "${APP_NAME} installed in namespace 'apps'."
echo "Check status: kubectl get pods -n apps"
