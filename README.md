# k3s-manifest

GitOps manifests for the k3s workshop cluster, structured after [nwl-k8s-manifest](https://github.com/NetworkLink2563/nwl-k8s-manifest): ArgoCD ApplicationSets driving per-app Helm charts, with cluster infrastructure split out under `infrastructure/`.

## Structure

- `namespaces/` — namespace definitions (`dev`, `test`, `monitoring`, `infra`)
- `apps/<name>/` — one Helm chart per app (`Chart.yaml`, `values.yaml` defaults, `values-<env>.yaml` overrides, `templates/`)
- `infrastructure/argocd/` — ArgoCD's own config (`argocd-cm.yaml`, `argocd-rbac.yaml`), ingress, and the `ApplicationSet`/`Application` objects that deploy everything else
- `infrastructure/cert-manager/` — `ClusterIssuer`s (self-signed root CA for the cluster; swap in a real ACME issuer if you get a public domain)
- `infrastructure/vault/` — Helm values for the in-cluster Vault server, plus its policies/roles
- `infrastructure/monitoring/` — `kube-prometheus-stack` values (Grafana + Prometheus)
- `bootstrap-infra.yaml` — root ArgoCD `Application` that points at `infrastructure/argocd/`, so once applied ArgoCD manages the rest of this repo itself
- `scripts/` — bootstrap and Vault setup helpers

Apps get secrets via the [Vault Agent Injector](https://developer.hashicorp.com/vault/docs/platform/k8s/injector) sidecar (see `vault.*` values in each app's `values.yaml`), not from raw Kubernetes Secrets.

## First-time cluster bootstrap

Ingress-nginx, cert-manager, and ArgoCD are chicken-and-egg with GitOps (ArgoCD needs an ingress controller before it can expose itself), so they're installed once via Helm rather than synced by ArgoCD:

```bash
./scripts/bootstrap-infra.sh
```

This installs ingress-nginx, cert-manager, ArgoCD, and kube-prometheus-stack, then applies `bootstrap-infra.yaml` — from that point on, ArgoCD watches `infrastructure/argocd/` and syncs Vault, the app ApplicationSets, and anything else added there.

Then initialize Vault (policies, Kubernetes auth, roles):

```bash
./scripts/setup-vault.sh
```

## Adding a new app

1. Copy `apps/nwl-wim-service/` as a template: `Chart.yaml`, `values.yaml`, `values-dev.yaml`, `values-test.yaml`, `templates/`.
2. Add a matching `<app>-appset.yaml` under `infrastructure/argocd/` (copy `nwl-wim-service-appset.yaml` and update the name/path).
3. If it needs secrets, add a policy under `infrastructure/vault/policies/` and a role under `infrastructure/vault/roles/`, then apply via `setup-vault.sh`.

## Notes

- Hostnames use the placeholder domain `k3s-workshop.local` — update them (or add `/etc/hosts` entries) to match your actual cluster DNS.
- `infrastructure/vault/values-vault.yaml` deploys Vault in `standalone` mode with file storage; after first install it needs manual `vault operator init` + `unseal` (unlike the old `-dev` mode deployment, this one persists data across restarts).
