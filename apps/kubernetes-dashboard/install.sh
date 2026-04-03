#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Adding kubernetes-dashboard Helm repo..."
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/ 2>/dev/null || true
helm repo update

echo "==> Installing/upgrading kubernetes-dashboard..."
helm upgrade --install kubernetes-dashboard \
  kubernetes-dashboard/kubernetes-dashboard \
  --namespace kubernetes-dashboard \
  --create-namespace \
  --values "${SCRIPT_DIR}/values.yaml" \
  --wait \
  --timeout 5m

echo "==> Creating admin service account..."
kubectl apply -f "${SCRIPT_DIR}/admin-user.yaml"

echo ""
echo "Kubernetes Dashboard installed."
echo ""
echo "To access the dashboard:"
echo "  1. Run in a separate terminal:"
echo "     kubectl port-forward -n kubernetes-dashboard svc/kubernetes-dashboard-kong-proxy 8443:443"
echo ""
echo "  2. Get your login token:"
echo "     kubectl -n kubernetes-dashboard create token admin-user"
echo ""
echo "  3. Open https://localhost:8443 in your browser"
echo "     (accept the self-signed certificate warning)"
echo "     Paste the token to log in."
