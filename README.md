# k8s-manifests

Infra & Kubernetes manifests for NWL platform

## Structure

- namespaces/: envs
- apps/: application deployments
- vault/: secrets & auth
- monitoring/: grafana/prometheus

## Deploy

kubectl apply -f namespaces/
kubectl apply -f apps/
