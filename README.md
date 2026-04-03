# ag_kube_frame

A local Kubernetes development framework built on minikube and Helm. Spin up a fully-featured cluster with Grafana and Prometheus monitoring in a single command, and add new applications using a simple, consistent convention.

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (running)
- [minikube](https://minikube.sigs.k8s.io/docs/start/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm 3](https://helm.sh/docs/intro/install/)

## Quick Start

```bash
# Clone the repo
git clone https://github.com/MeanGreen256/ag_kube_frame.git
cd ag_kube_frame

# Start the cluster and install monitoring
make start
```

That's it. After a few minutes you'll have a running Kubernetes cluster with Grafana and Prometheus installed.

## Features

- **One-command setup** — `make start` provisions the cluster, enables addons, and installs monitoring
- **Grafana + Prometheus** — pre-configured via `kube-prometheus-stack` with dashboards for node metrics, pod resource usage, and the Kubernetes API server
- **Simple app convention** — add any Helm-based application by dropping a `values.yaml` and `install.sh` into `apps/<app-name>/`
- **Configurable resources** — control cluster CPU and memory via environment variables
- **Idempotent** — all install scripts use `helm upgrade --install`, safe to run multiple times

## Usage

### Cluster Lifecycle

```bash
make start          # Start cluster and install monitoring
make stop           # Stop the cluster (preserves state)
make reset          # Delete and recreate the cluster from scratch
make status         # Show minikube status and all running pods
```

### Monitoring

```bash
make monitoring               # Install or upgrade Grafana + Prometheus
make port-forward-grafana     # Access Grafana at http://localhost:3000
make port-forward-prometheus  # Access Prometheus at http://localhost:9090
```

Default Grafana credentials: `admin` / `admin`

To set a custom password:

```bash
GRAFANA_PASSWORD=mysecretpassword make start
```

### Applications

```bash
make app APP=example-app        # Install or upgrade an app
make app-remove APP=example-app # Uninstall an app
```

### Help

```bash
make help  # List all available targets
```

## Configuration

| Environment Variable | Default | Description |
|---|---|---|
| `MINIKUBE_CPUS` | `2` | CPUs allocated to minikube |
| `MINIKUBE_MEMORY` | `4096` | Memory (MB) allocated to minikube |
| `GRAFANA_PASSWORD` | `admin` | Grafana admin password |

Example:

```bash
MINIKUBE_CPUS=4 MINIKUBE_MEMORY=8192 make start
```

## Adding a New Application

Each application lives in its own directory under `apps/` and requires two files:

```
apps/
└── my-app/
    ├── values.yaml   # Helm values overrides for the app's chart
    └── install.sh    # Adds the Helm repo and runs helm upgrade --install
```

**Step 1 — Create the directory and values file:**

```bash
mkdir apps/my-app
```

```yaml
# apps/my-app/values.yaml
replicaCount: 1
service:
  type: ClusterIP
```

**Step 2 — Create the install script:**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="$(basename "${SCRIPT_DIR}")"

helm repo add <repo-name> <repo-url> 2>/dev/null || true
helm repo update

helm upgrade --install "${APP_NAME}" \
  <repo-name>/<chart-name> \
  --namespace apps \
  --create-namespace \
  --values "${SCRIPT_DIR}/values.yaml" \
  --wait \
  --timeout 5m

echo "${APP_NAME} installed in namespace 'apps'."
```

```bash
chmod +x apps/my-app/install.sh
```

**Step 3 — Install it:**

```bash
make app APP=my-app
```

See `apps/example-app/` for a working reference using `bitnami/nginx`.

## Included Apps

### podinfo

A lightweight app that displays pod information (name, namespace, version) in a browser. Good for verifying the full install → port-forward → browser flow.

```bash
# Install
make app APP=podinfo

# Access (run in a dedicated terminal, leave it open)
kubectl port-forward -n apps svc/podinfo 9898:9898

# Open in browser
http://localhost:9898
```

### Kubernetes Dashboard

A full web UI for viewing and managing all resources in your cluster — pods, deployments, services, logs, and resource usage across all namespaces.

```bash
# Install
make app APP=kubernetes-dashboard
```

**Access (3 steps):**

```bash
# Step 1 — port-forward in a dedicated terminal (leave it open)
kubectl port-forward -n kubernetes-dashboard svc/kubernetes-dashboard-kong-proxy 8443:443

# Step 2 — get your login token (run in a separate terminal)
kubectl -n kubernetes-dashboard create token admin-user

# Step 3 — open in browser
https://localhost:8443
```

> Safari will warn about a self-signed certificate — click **Show Details → Visit Website** to proceed. Paste the token from Step 2 to log in.

---

## Repository Structure

```
ag_kube_frame/
├── Makefile                        # Entry point for all operations
├── scripts/
│   ├── cluster-start.sh            # Start minikube, enable addons, apply namespaces
│   ├── cluster-stop.sh             # Stop minikube
│   ├── cluster-reset.sh            # Delete and recreate cluster
│   └── port-forward.sh             # Port-forward Grafana or Prometheus
├── cluster/
│   └── namespaces.yaml             # monitoring and apps namespaces
├── monitoring/
│   ├── values.yaml                 # kube-prometheus-stack Helm overrides
│   └── install.sh                  # Installs Grafana + Prometheus
└── apps/
    ├── example-app/                # Reference app (bitnami/nginx)
    ├── podinfo/                    # Pod info viewer
    └── kubernetes-dashboard/       # Kubernetes web UI
```

## Namespaces

| Namespace | Purpose |
|---|---|
| `monitoring` | Grafana, Prometheus, and related components |
| `apps` | User-deployed applications (podinfo, example-app, etc.) |
| `kubernetes-dashboard` | Kubernetes Dashboard web UI |

## Monitoring Details

Monitoring is provided by the [`kube-prometheus-stack`](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) Helm chart, which bundles:

- **Prometheus** — metrics collection, 24h retention (configurable in `monitoring/values.yaml`)
- **Grafana** — pre-built dashboards for cluster nodes, pod resources, and the Kubernetes API
- **kube-state-metrics** — Kubernetes object metrics
- **node-exporter** — host-level metrics

Alertmanager is disabled by default to reduce noise in a local dev environment. To enable it, set `alertmanager.enabled: true` in `monitoring/values.yaml`.
