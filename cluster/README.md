# cluster/

Contains cluster-level Kubernetes resources applied once during cluster setup.

## Files

- `namespaces.yaml` — Creates the `monitoring` and `apps` namespaces. Applied automatically by `scripts/cluster-start.sh`.

## Manual apply

```bash
kubectl apply -f cluster/namespaces.yaml
```
