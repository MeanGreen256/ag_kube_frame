#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Adding prometheus-community Helm repo..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo update

echo "==> Installing/upgrading kube-prometheus-stack..."
helm upgrade --install kube-prometheus-stack \
  prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values "${SCRIPT_DIR}/values.yaml" \
  --set "grafana.adminPassword=${GRAFANA_PASSWORD:-admin}" \
  --wait \
  --timeout 10m

echo ""
echo "Monitoring installed."
echo "Run 'make port-forward-grafana' to access Grafana at http://localhost:3000"
echo "Default credentials: admin / ${GRAFANA_PASSWORD:-admin}"
