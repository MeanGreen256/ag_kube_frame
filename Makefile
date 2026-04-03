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
