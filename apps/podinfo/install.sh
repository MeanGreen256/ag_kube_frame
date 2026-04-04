#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="$(basename "${SCRIPT_DIR}")"

echo "==> Adding podinfo Helm repo..."
helm repo add podinfo https://stefanprodan.github.io/podinfo 2>/dev/null || true
helm repo update

echo "==> Installing/upgrading ${APP_NAME}..."
helm upgrade --install "${APP_NAME}" \
  podinfo/podinfo \
  --namespace apps \
  --create-namespace \
  --values "${SCRIPT_DIR}/values.yaml" \
  --wait \
  --timeout 5m

echo "==> Applying ServiceMonitor for Prometheus scraping..."
kubectl apply -f "${SCRIPT_DIR}/service-monitor.yaml"

echo ""
echo "${APP_NAME} installed in namespace 'apps'."
echo "Access it: kubectl port-forward -n apps svc/podinfo 9898:9898"
echo "Then open: http://localhost:9898"
echo ""
echo "Metrics are scraped by Prometheus. Check targets at http://localhost:9090/targets"
