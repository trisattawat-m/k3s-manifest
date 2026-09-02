# ============================================================================
# File: scripts/setup-vault.sh
# Description: Initialize Vault (deployed via infrastructure/vault) with the
# KV engine, Kubernetes auth, and the nwl-wim-service policy/role.
# ============================================================================
#!/bin/bash
set -e

VAULT_ADDR="${VAULT_ADDR:-https://vault.k3s-workshop.local}"
VAULT_TOKEN="${VAULT_TOKEN:-root}"
VAULT_NAMESPACE="dev"
K8S_HOST="${K8S_HOST:-https://kubernetes.default.svc}"

echo "🔐 Setting up Vault integration..."

export VAULT_ADDR
export VAULT_TOKEN

echo "⏳ Waiting for Vault to be ready..."
until vault status > /dev/null 2>&1; do
  echo "   Waiting for Vault..."
  sleep 2
done
echo "✅ Vault is ready"

echo "📦 Enabling KV v2 secrets engine at network-link/..."
vault secrets enable -path=network-link kv-v2 2>/dev/null || echo "   KV v2 already enabled"

echo "📋 Creating policy: nwl-wim-service"
vault policy write nwl-wim-service infrastructure/vault/policies/nwl-wim-service.hcl

echo "📋 Creating identity-aware policy: vault-policy"
vault policy write vault-policy infrastructure/vault/policies/vault-policy.hcl

echo "🔑 Enabling Kubernetes auth..."
vault auth enable kubernetes 2>/dev/null || echo "   Kubernetes auth already enabled"

echo "📜 Getting Kubernetes credentials..."
K8S_CA_CERT=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d)
K8S_TOKEN=$(kubectl create token nwl-wim-service -n $VAULT_NAMESPACE)

echo "⚙️  Configuring Kubernetes auth..."
vault write auth/kubernetes/config \
  token_reviewer_jwt="$K8S_TOKEN" \
  kubernetes_host="$K8S_HOST" \
  kubernetes_ca_cert="$K8S_CA_CERT" \
  disable_local_ca_jwt=false

echo "👤 Creating role: nwl-wim-service"
vault write auth/kubernetes/role/nwl-wim-service \
  bound_service_account_names=nwl-wim-service \
  bound_service_account_namespaces=dev,test \
  policies=nwl-wim-service \
  audience=vault \
  ttl=24h \
  max_ttl=48h

echo "🔐 Creating sample secrets..."
vault kv put network-link/dev/nwl-wim-service \
  database_url="postgresql://dev-user:dev-pass@postgres:5432/devdb" \
  api_key="dev-api-key-12345" \
  secret_key="dev-secret-key-67890"

vault kv put network-link/test/nwl-wim-service \
  database_url="postgresql://test-user:test-pass@postgres:5432/testdb" \
  api_key="test-api-key-12345" \
  secret_key="test-secret-key-67890"

echo ""
echo "✅ Vault setup complete!"
echo ""
echo "📋 Summary:"
echo "  - Policy created: nwl-wim-service"
echo "  - Role created: nwl-wim-service (SA: nwl-wim-service, namespaces: dev, test)"
echo "  - Secrets created:"
echo "    • network-link/dev/nwl-wim-service"
echo "    • network-link/test/nwl-wim-service"
echo ""
echo "🔍 Test the configuration:"
echo "  vault read auth/kubernetes/role/nwl-wim-service"
echo "  vault policy read nwl-wim-service"
echo "  vault kv get network-link/dev/nwl-wim-service"
