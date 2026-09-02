#!/bin/bash
# ============================================================================
# File: scripts/bootstrap-infra.sh
# Description: One-time cluster bootstrap. Installs the components ArgoCD
# itself depends on (ingress-nginx, cert-manager, ArgoCD), then hands off
# GitOps management of everything else to ArgoCD via bootstrap-infra.yaml.
# ============================================================================
set -e

echo "Namespaces..."
kubectl apply -f namespaces/

echo "ingress-nginx..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx 2>/dev/null || true
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace

echo "cert-manager..."
helm repo add jetstack https://charts.jetstack.io 2>/dev/null || true
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace --set installCRDs=true

echo "Waiting for cert-manager to be ready..."
kubectl wait --for=condition=Available deployment --all -n cert-manager --timeout=120s

echo "ClusterIssuers..."
kubectl apply -f infrastructure/cert-manager/

echo "ArgoCD..."
helm repo add argo https://argoproj.github.io/argo-helm 2>/dev/null || true
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd --create-namespace

echo "kube-prometheus-stack (grafana + prometheus)..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  -f infrastructure/monitoring/values-monitoring.yaml

echo "Handing off to ArgoCD (Vault, apps, ApplicationSets)..."
kubectl apply -f bootstrap-infra.yaml

echo ""
echo "Bootstrap complete. ArgoCD will now sync infrastructure/argocd/ automatically."
echo "Check status with: kubectl get applications -n argocd"
