# Local Kubernetes Framework Design

**Date:** 2026-04-03
**Status:** Approved

## Overview

A code repository that provisions a local Kubernetes cluster using minikube, provides a structured convention for adding applications via Helm, and includes Grafana and Prometheus for cluster observability — all managed through a Makefile + shell scripts interface.

## Goals

- Reproducible local Kubernetes setup runnable with a single command
- Clean conventions for adding new applications without modifying shared infrastructure
- Out-of-the-box observability via Grafana and Prometheus
- Usable as both a learning environment and a local development platform

## Repository Structure

```
ag_kube_framework/
├── Makefile                        # Entry point: start, stop, reset, status, help
├── scripts/
│   ├── cluster-start.sh            # minikube start with config
│   ├── cluster-stop.sh             # minikube stop
│   ├── cluster-reset.sh            # minikube delete + restart
│   └── port-forward.sh             # convenience port-forwarding (Grafana, etc.)
├── cluster/
│   ├── namespaces.yaml             # monitoring and apps namespaces
│   └── README.md
├── monitoring/
│   ├── values.yaml                 # kube-prometheus-stack Helm overrides
│   └── install.sh                  # helm repo add + helm upgrade --install
└── apps/
    └── example-app/
        ├── values.yaml             # Helm values for the app
        └── install.sh              # helm upgrade --install for this app
```

## Cluster Lifecycle

**Tool:** minikube with Docker driver

**`scripts/cluster-start.sh`:**
1. Validates that `minikube` and `helm` are installed; exits with a clear error if not
2. Starts minikube with CPU and memory configurable via `MINIKUBE_CPUS` (default: 2) and `MINIKUBE_MEMORY` (default: 4096) environment variables
3. Enables minikube addons: `ingress`, `metrics-server`
4. Applies `cluster/namespaces.yaml` to create `monitoring` and `apps` namespaces

**`scripts/cluster-stop.sh`:** Runs `minikube stop`

**`scripts/cluster-reset.sh`:** Runs `minikube delete` then calls `cluster-start.sh`

**Makefile targets:**

| Target | Description |
|--------|-------------|
| `make start` | Start cluster + install monitoring |
| `make stop` | Stop cluster |
| `make reset` | Delete and recreate cluster from scratch |
| `make status` | Show minikube status and running pods |
| `make monitoring` | Install/upgrade kube-prometheus-stack |
| `make app APP=<name>` | Install/upgrade a named app |
| `make app-remove APP=<name>` | Uninstall a named app |
| `make port-forward-grafana` | Forward Grafana to localhost:3000 |
| `make help` | List all targets with descriptions |

## Monitoring

**Chart:** `prometheus-community/kube-prometheus-stack`
**Namespace:** `monitoring`

**`monitoring/install.sh`:**
1. Adds `prometheus-community` Helm repo and runs `helm repo update`
2. Runs `helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack --namespace monitoring -f monitoring/values.yaml`

**`monitoring/values.yaml` configuration:**
- **Grafana:** admin password overridable via `GRAFANA_PASSWORD` env var (default: `admin`); persistence disabled (local dev)
- **Prometheus:** 24h retention to avoid laptop disk pressure
- **Alertmanager:** disabled by default (reduces noise in a learning environment; re-enable by setting `alertmanager.enabled: true`)

**Pre-built dashboards** (provided by kube-prometheus-stack):
- Cluster node metrics
- Pod resource usage (CPU, memory)
- Kubernetes API server

Grafana accessible at `localhost:3000` via `make port-forward-grafana`.

## Application Management

**Namespace:** `apps`

Each application follows a consistent directory convention under `apps/<app-name>/`:

| File | Purpose |
|------|---------|
| `values.yaml` | Helm values overrides for the app's chart |
| `install.sh` | Adds Helm repo (if needed) and runs `helm upgrade --install` |

**Adding a new app:**
1. Create `apps/<app-name>/`
2. Add `values.yaml` and `install.sh`
3. Run `make app APP=<app-name>`

No changes to any shared infrastructure files are required.

**Reference implementation:** `apps/example-app/` uses `bitnami/nginx` to demonstrate the full pattern.

## Decisions

| Decision | Choice | Reason |
|----------|--------|--------|
| Local K8s tool | minikube | Most popular, best addon ecosystem, well-documented |
| Package manager | Helm | De facto standard; official charts for Grafana/Prometheus |
| Monitoring bundle | kube-prometheus-stack | Pre-wired Grafana + Prometheus + dashboards, no manual wiring |
| App structure | One Helm install per app in `apps/` | Self-contained, no inter-app coupling, easy to add/remove |
| Lifecycle interface | Makefile + shell scripts | Makefile for discoverability, scripts for complex multi-step logic |
| Alertmanager | Disabled by default | Reduces noise; learning environment doesn't need paging |
| Persistence | Disabled by default | Local dev doesn't need data durability across resets |
