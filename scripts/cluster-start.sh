#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

MINIKUBE_CPUS="${MINIKUBE_CPUS:-2}"
MINIKUBE_MEMORY="${MINIKUBE_MEMORY:-4096}"

# --- Dependency check ---
check_dep() {
  if ! command -v "$1" &>/dev/null; then
    echo "ERROR: '$1' is not installed or not in PATH." >&2
    echo "Install it and re-run." >&2
    exit 1
  fi
}

check_dep minikube
check_dep helm
check_dep kubectl

echo "==> Starting minikube (CPUs=${MINIKUBE_CPUS}, Memory=${MINIKUBE_MEMORY}MB)..."
minikube start \
  --driver=docker \
  --cpus="${MINIKUBE_CPUS}" \
  --memory="${MINIKUBE_MEMORY}"

echo "==> Enabling addons: ingress, metrics-server..."
minikube addons enable ingress
minikube addons enable metrics-server

echo "==> Applying cluster namespaces..."
kubectl apply -f "${REPO_ROOT}/cluster/namespaces.yaml"

echo ""
echo "Cluster is ready."
echo "Run 'make monitoring' to install Grafana + Prometheus."
