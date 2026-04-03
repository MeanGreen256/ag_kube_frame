#!/usr/bin/env bash
set -euo pipefail

SERVICE="${1:-grafana}"

case "${SERVICE}" in
  grafana)
    echo "==> Forwarding Grafana to http://localhost:3000 (Ctrl+C to stop)..."
    kubectl port-forward \
      --namespace monitoring \
      svc/kube-prometheus-stack-grafana \
      3000:80
    ;;
  prometheus)
    echo "==> Forwarding Prometheus to http://localhost:9090 (Ctrl+C to stop)..."
    kubectl port-forward \
      --namespace monitoring \
      svc/kube-prometheus-stack-prometheus \
      9090:9090
    ;;
  *)
    echo "ERROR: Unknown service '${SERVICE}'. Supported: grafana, prometheus" >&2
    exit 1
    ;;
esac
