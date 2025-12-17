# ============================================================================
# File: vault/scripts/setup-vault.sh
# Description: Initialize Vault with policies and roles
# ============================================================================
#!/bin/bash
set -e

VAULT_ADDR="${VAULT_ADDR:-http://10.15.15.116:30080/vault}"
VAULT_TOKEN="${VAULT_TOKEN:-root}"
VAULT_NAMESPACE="dev"
K8S_HOST="${K8S_HOST:-https://kubernetes.default.svc}"

echo "🔐 Setting up Vault integration..."

# Export Vault address and token
export VAULT_ADDR
export VAULT_TOKEN

# Wait for Vault to be ready
echo "⏳ Waiting for Vault to be ready..."
until vault status > /dev/null 2>&1; do
  echo "   Waiting for Vault..."
  sleep 2
done
echo "✅ Vault is ready"

# Enable KV v2 secrets engine if not already enabled
echo "📦 Enabling KV v2 secrets engine..."
vault secrets enable -path=secret kv-v2 2>/dev/null || echo "   KV v2 already enabled"

# Create policy
echo "📋 Creating policy: nwl-wim-service"
vault policy write nwl-wim-service - <<EOF
# Path: secret/data/dev/nwl-wim-service
path "secret/data/dev/nwl-wim-service" {
  capabilities = ["read", "create", "update"]
}

# Path: secret/data/test/nwl-wim-service
path "secret/data/test/nwl-wim-service" {
  capabilities = ["read", "create", "update"]
}

# Allow listing secrets
path "secret/metadata/dev/nwl-wim-service" {
  capabilities = ["list", "read"]
}

path "secret/metadata/test/nwl-wim-service" {
  capabilities = ["list", "read"]
}

# Allow renewing tokens
path "auth/token/renew-self" {
  capabilities = ["update"]
}

# Allow looking up token information
path "auth/token/lookup-self" {
  capabilities = ["read"]
}
EOF

# Enable Kubernetes auth if not already enabled
echo "🔑 Enabling Kubernetes auth..."
vault auth enable kubernetes 2>/dev/null || echo "   Kubernetes auth already enabled"

# Get Kubernetes CA cert and token
echo "📜 Getting Kubernetes credentials..."
K8S_CA_CERT=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d)
K8S_TOKEN=$(kubectl get secret -n $VAULT_NAMESPACE $(kubectl get sa nwl-wim-sa -n $VAULT_NAMESPACE -o jsonpath='{.secrets[0].name}' 2>/dev/null || echo "nwl-wim-sa-token") -o jsonpath='{.data.token}' 2>/dev/null | base64 -d || kubectl create token nwl-wim-sa -n $VAULT_NAMESPACE)

# Configure Kubernetes auth
echo "⚙️  Configuring Kubernetes auth..."
vault write auth/kubernetes/config \
  token_reviewer_jwt="$K8S_TOKEN" \
  kubernetes_host="$K8S_HOST" \
  kubernetes_ca_cert="$K8S_CA_CERT" \
  disable_local_ca_jwt=false

# Create role
echo "👤 Creating role: nwl-wim-service"
vault write auth/kubernetes/role/nwl-wim-service \
  bound_service_account_names=nwl-wim-sa \
  bound_service_account_namespaces=dev,test \
  policies=nwl-wim-service \
  audience=vault \
  ttl=24h \
  max_ttl=48h

# Create sample secrets
echo "🔐 Creating sample secrets..."
vault kv put secret/dev/nwl-wim-service \
  database_url="postgresql://dev-user:dev-pass@postgres:5432/devdb" \
  api_key="dev-api-key-12345" \
  secret_key="dev-secret-key-67890"

vault kv put secret/test/nwl-wim-service \
  database_url="postgresql://test-user:test-pass@postgres:5432/testdb" \
  api_key="test-api-key-12345" \
  secret_key="test-secret-key-67890"

echo ""
echo "✅ Vault setup complete!"
echo ""
echo "📋 Summary:"
echo "  - Policy created: nwl-wim-service"
echo "  - Role created: nwl-wim-service"
echo "  - Secrets created:"
echo "    • secret/dev/nwl-wim-service"
echo "    • secret/test/nwl-wim-service"
echo ""
echo "🔍 Test the configuration:"
echo "  vault read auth/kubernetes/role/nwl-wim-service"
echo "  vault policy read nwl-wim-service"
echo "  vault kv get secret/dev/nwl-wim-service"
