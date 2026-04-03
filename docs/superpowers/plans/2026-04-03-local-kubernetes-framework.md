# Local Kubernetes Framework Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a reproducible local Kubernetes environment using minikube, Helm, Grafana, and Prometheus — runnable with `make start`.

**Architecture:** A Makefile delegates to shell scripts in `scripts/` for cluster lifecycle operations. Applications are installed as independent Helm releases under `apps/<name>/`. Monitoring is a first-class citizen installed into its own `monitoring` namespace via `kube-prometheus-stack`.

**Tech Stack:** minikube, Helm 3, kube-prometheus-stack chart, bitnami/nginx (example app), bash, Make

---

## File Map

| File | Responsibility |
|------|---------------|
| `Makefile` | User-facing entry point for all operations |
| `scripts/cluster-start.sh` | Validate deps, start minikube, enable addons, apply namespaces |
| `scripts/cluster-stop.sh` | Stop minikube |
| `scripts/cluster-reset.sh` | Delete cluster and restart from scratch |
| `scripts/port-forward.sh` | Port-forward services to localhost |
| `cluster/namespaces.yaml` | Kubernetes Namespace manifests |
| `cluster/README.md` | Cluster directory documentation |
| `monitoring/values.yaml` | kube-prometheus-stack Helm values overrides |
| `monitoring/install.sh` | Add Helm repo and install kube-prometheus-stack |
| `apps/example-app/values.yaml` | Helm values for bitnami/nginx example |
| `apps/example-app/install.sh` | Install example-app via Helm |

---

## Task 1: Initialize Repository Structure

**Files:**
- Create: `.gitignore`
- Create: `scripts/` directory (empty, via placeholder)
- Create: `cluster/` directory
- Create: `monitoring/` directory
- Create: `apps/example-app/` directory

- [ ] **Step 1: Create .gitignore**

```gitignore
# OS
.DS_Store
Thumbs.db

# Editor
.idea/
.vscode/
*.swp
*.swo

# Helm
*.tgz
charts/

# Local overrides (never commit secrets)
*.local.yaml
.env
```

Save to `.gitignore`.

- [ ] **Step 2: Create directory placeholders**

```bash
mkdir -p scripts cluster monitoring apps/example-app
touch scripts/.gitkeep cluster/.gitkeep monitoring/.gitkeep apps/example-app/.gitkeep
```

- [ ] **Step 3: Commit**

```bash
git add .gitignore scripts/.gitkeep cluster/.gitkeep monitoring/.gitkeep apps/example-app/.gitkeep
git commit -m "chore: initialize repository structure"
```

---

## Task 2: Create Namespace Manifest

**Files:**
- Create: `cluster/namespaces.yaml`

- [ ] **Step 1: Write namespaces.yaml**

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: monitoring
  labels:
    app.kubernetes.io/managed-by: ag-kube-framework
---
apiVersion: v1
kind: Namespace
metadata:
  name: apps
  labels:
    app.kubernetes.io/managed-by: ag-kube-framework
```

Save to `cluster/namespaces.yaml`.

- [ ] **Step 2: Validate YAML syntax**

```bash
python3 -c "import yaml; list(yaml.safe_load_all(open('cluster/namespaces.yaml')))" && echo "YAML valid"
```

Expected: `YAML valid`

- [ ] **Step 3: Create cluster/README.md**

```markdown
# cluster/

Contains cluster-level Kubernetes resources applied once during cluster setup.

## Files

- `namespaces.yaml` — Creates the `monitoring` and `apps` namespaces. Applied automatically by `scripts/cluster-start.sh`.

## Manual apply

```bash
kubectl apply -f cluster/namespaces.yaml
```
```

Save to `cluster/README.md`.

- [ ] **Step 4: Commit**

```bash
git add cluster/namespaces.yaml cluster/README.md
git rm cluster/.gitkeep
git commit -m "feat: add namespace manifest and cluster README"
```

---

## Task 3: Create cluster-start.sh

**Files:**
- Create: `scripts/cluster-start.sh`

- [ ] **Step 1: Write cluster-start.sh**

```bash
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
```

Save to `scripts/cluster-start.sh`.

- [ ] **Step 2: Make executable and validate syntax**

```bash
chmod +x scripts/cluster-start.sh
bash -n scripts/cluster-start.sh && echo "Syntax OK"
```

Expected: `Syntax OK`

- [ ] **Step 3: Commit**

```bash
git add scripts/cluster-start.sh
git rm scripts/.gitkeep
git commit -m "feat: add cluster-start.sh"
```

---

## Task 4: Create cluster-stop.sh and cluster-reset.sh

**Files:**
- Create: `scripts/cluster-stop.sh`
- Create: `scripts/cluster-reset.sh`

- [ ] **Step 1: Write cluster-stop.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "==> Stopping minikube..."
minikube stop
echo "Cluster stopped."
```

Save to `scripts/cluster-stop.sh`.

- [ ] **Step 2: Write cluster-reset.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Deleting minikube cluster..."
minikube delete

echo "==> Recreating cluster..."
"${SCRIPT_DIR}/cluster-start.sh"
```

Save to `scripts/cluster-reset.sh`.

- [ ] **Step 3: Make executable and validate syntax**

```bash
chmod +x scripts/cluster-stop.sh scripts/cluster-reset.sh
bash -n scripts/cluster-stop.sh && echo "cluster-stop.sh: Syntax OK"
bash -n scripts/cluster-reset.sh && echo "cluster-reset.sh: Syntax OK"
```

Expected: Both lines print `Syntax OK`.

- [ ] **Step 4: Commit**

```bash
git add scripts/cluster-stop.sh scripts/cluster-reset.sh
git commit -m "feat: add cluster-stop.sh and cluster-reset.sh"
```

---

## Task 5: Create port-forward.sh

**Files:**
- Create: `scripts/port-forward.sh`

- [ ] **Step 1: Write port-forward.sh**

```bash
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
```

Save to `scripts/port-forward.sh`.

- [ ] **Step 2: Make executable and validate syntax**

```bash
chmod +x scripts/port-forward.sh
bash -n scripts/port-forward.sh && echo "Syntax OK"
```

Expected: `Syntax OK`

- [ ] **Step 3: Commit**

```bash
git add scripts/port-forward.sh
git commit -m "feat: add port-forward.sh for Grafana and Prometheus"
```

---

## Task 6: Create monitoring/values.yaml

**Files:**
- Create: `monitoring/values.yaml`

- [ ] **Step 1: Write monitoring/values.yaml**

```yaml
# kube-prometheus-stack Helm values
# Full reference: https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/values.yaml
#
# NOTE: adminPassword is set via --set in monitoring/install.sh using $GRAFANA_PASSWORD env var.
# Do not put secrets directly in this file.

grafana:
  enabled: true
  adminPassword: admin  # Overridden at install time via --set if GRAFANA_PASSWORD is set
  persistence:
    enabled: false
  ingress:
    enabled: false  # Access via port-forward: make port-forward-grafana

prometheus:
  prometheusSpec:
    retention: 24h
    resources:
      requests:
        memory: 256Mi
        cpu: 100m
      limits:
        memory: 512Mi

alertmanager:
  enabled: false  # Disable to reduce noise in local dev. Set to true to enable.

# Reduce resource footprint for local dev
kubeStateMetrics:
  enabled: true

nodeExporter:
  enabled: true
```

Save to `monitoring/values.yaml`.

- [ ] **Step 2: Validate YAML syntax**

```bash
python3 -c "import yaml; yaml.safe_load(open('monitoring/values.yaml'))" && echo "YAML valid"
```

Expected: `YAML valid`

- [ ] **Step 3: Commit**

```bash
git add monitoring/values.yaml
git commit -m "feat: add kube-prometheus-stack Helm values"
```

---

## Task 7: Create monitoring/install.sh

**Files:**
- Create: `monitoring/install.sh`

- [ ] **Step 1: Write monitoring/install.sh**

```bash
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
```

Save to `monitoring/install.sh`.

- [ ] **Step 2: Make executable and validate syntax**

```bash
chmod +x monitoring/install.sh
bash -n monitoring/install.sh && echo "Syntax OK"
```

Expected: `Syntax OK`

- [ ] **Step 3: Commit**

```bash
git add monitoring/install.sh
git rm monitoring/.gitkeep
git commit -m "feat: add monitoring install script"
```

---

## Task 8: Create apps/example-app

**Files:**
- Create: `apps/example-app/values.yaml`
- Create: `apps/example-app/install.sh`

- [ ] **Step 1: Write apps/example-app/values.yaml**

```yaml
# bitnami/nginx Helm values for example-app
# Full reference: https://github.com/bitnami/charts/tree/main/bitnami/nginx

replicaCount: 1

service:
  type: ClusterIP
  port: 80

resources:
  requests:
    memory: 64Mi
    cpu: 50m
  limits:
    memory: 128Mi
    cpu: 100m
```

Save to `apps/example-app/values.yaml`.

- [ ] **Step 2: Write apps/example-app/install.sh**

```bash
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
```

Save to `apps/example-app/install.sh`.

- [ ] **Step 3: Make executable and validate syntax**

```bash
chmod +x apps/example-app/install.sh
bash -n apps/example-app/install.sh && echo "Syntax OK"
```

Expected: `Syntax OK`

- [ ] **Step 4: Commit**

```bash
git add apps/example-app/values.yaml apps/example-app/install.sh
git rm apps/example-app/.gitkeep
git commit -m "feat: add example-app (bitnami/nginx) demonstrating app convention"
```

---

## Task 9: Create Makefile

**Files:**
- Create: `Makefile`

- [ ] **Step 1: Write Makefile**

```makefile
SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

SCRIPTS := scripts
APP ?= $(error APP is not set. Usage: make app APP=<name>)

##@ Cluster Lifecycle

.PHONY: start
start: ## Start cluster and install monitoring
	@$(SCRIPTS)/cluster-start.sh
	@$(MAKE) monitoring

.PHONY: stop
stop: ## Stop the minikube cluster
	@$(SCRIPTS)/cluster-stop.sh

.PHONY: reset
reset: ## Delete and recreate the cluster from scratch
	@$(SCRIPTS)/cluster-reset.sh

.PHONY: status
status: ## Show cluster and pod status
	@echo "=== Minikube Status ==="
	@minikube status
	@echo ""
	@echo "=== Pods (all namespaces) ==="
	@kubectl get pods --all-namespaces

##@ Monitoring

.PHONY: monitoring
monitoring: ## Install or upgrade Grafana + Prometheus (kube-prometheus-stack)
	@monitoring/install.sh

.PHONY: port-forward-grafana
port-forward-grafana: ## Forward Grafana to http://localhost:3000
	@scripts/port-forward.sh grafana

.PHONY: port-forward-prometheus
port-forward-prometheus: ## Forward Prometheus to http://localhost:9090
	@scripts/port-forward.sh prometheus

##@ Applications

.PHONY: app
app: ## Install or upgrade an app. Usage: make app APP=<name>
	@if [ ! -d "apps/$(APP)" ]; then \
		echo "ERROR: apps/$(APP) does not exist." >&2; \
		echo "Create the directory with values.yaml and install.sh first." >&2; \
		exit 1; \
	fi
	@apps/$(APP)/install.sh

.PHONY: app-remove
app-remove: ## Uninstall an app. Usage: make app-remove APP=<name>
	@echo "==> Uninstalling $(APP) from namespace apps..."
	@helm uninstall "$(APP)" --namespace apps
	@echo "$(APP) uninstalled."

##@ Help

.PHONY: help
help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
```

Save to `Makefile`.

- [ ] **Step 2: Validate Makefile syntax**

```bash
make --dry-run help 2>&1 | head -5
```

Expected: Output shows the help text with target names and descriptions (no "Error" lines).

- [ ] **Step 3: Commit**

```bash
git add Makefile
git commit -m "feat: add Makefile with all lifecycle and app management targets"
```

---

## Task 10: Smoke Test and Final Commit

- [ ] **Step 1: Verify all scripts are executable**

```bash
ls -la scripts/*.sh monitoring/install.sh apps/example-app/install.sh
```

Expected: All files show `-rwxr-xr-x` permissions (the `x` bit is set).

- [ ] **Step 2: Validate all shell script syntax in one pass**

```bash
for f in scripts/*.sh monitoring/install.sh apps/example-app/install.sh; do
  bash -n "$f" && echo "OK: $f"
done
```

Expected: Every file prints `OK: <path>`.

- [ ] **Step 3: Validate all YAML files**

```bash
for f in cluster/namespaces.yaml monitoring/values.yaml apps/example-app/values.yaml; do
  python3 -c "import yaml; list(yaml.safe_load_all(open('$f')))" && echo "OK: $f"
done
```

Expected: Every file prints `OK: <path>`.

- [ ] **Step 4: Verify make help output**

```bash
make help
```

Expected output includes these targets: `start`, `stop`, `reset`, `status`, `monitoring`, `port-forward-grafana`, `port-forward-prometheus`, `app`, `app-remove`, `help`.

- [ ] **Step 5: Verify final repo structure**

```bash
find . -not -path './.git/*' -not -name '.gitkeep' | sort
```

Expected output:
```
.
./.gitignore
./Makefile
./apps
./apps/example-app
./apps/example-app/install.sh
./apps/example-app/values.yaml
./cluster
./cluster/README.md
./cluster/namespaces.yaml
./docs
./docs/superpowers
./docs/superpowers/plans
./docs/superpowers/plans/2026-04-03-local-kubernetes-framework.md
./docs/superpowers/specs
./docs/superpowers/specs/2026-04-03-local-kubernetes-framework-design.md
./monitoring
./monitoring/install.sh
./monitoring/values.yaml
./scripts
./scripts/cluster-reset.sh
./scripts/cluster-start.sh
./scripts/cluster-stop.sh
./scripts/port-forward.sh
```

- [ ] **Step 6: Final commit**

```bash
git add -A
git status  # verify only expected files are staged
git commit -m "chore: finalize repo structure and validate all files"
```

---

## Post-Implementation: Manual Verification

Once all tasks are complete, run the following to verify the full system works end-to-end:

```bash
# 1. Start the cluster (takes ~3-5 minutes on first run)
make start

# 2. Check everything is running
make status

# 3. Verify Grafana is accessible
make port-forward-grafana
# Open http://localhost:3000 in your browser
# Login: admin / admin (or $GRAFANA_PASSWORD)

# 4. Install the example app
make app APP=example-app

# 5. Verify example-app pod is running
kubectl get pods -n apps

# 6. Remove example app
make app-remove APP=example-app
```
