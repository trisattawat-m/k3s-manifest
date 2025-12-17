# ============================================================================
# File: vault/scripts/test-vault-access.sh
# Description: Test Vault access from a pod
# ============================================================================
#!/bin/bash
set -e

NAMESPACE="${1:-dev}"
VAULT_ADDR="http://vault.dev.svc.cluster.local:8200"

echo "🧪 Testing Vault access from namespace: $NAMESPACE"

# Create a test pod with the service account
kubectl run vault-test-$NAMESPACE \
  --image=hashicorp/vault:latest \
  --serviceaccount=nwl-wim-sa \
  --namespace=$NAMESPACE \
  --restart=Never \
  --rm -i --tty -- /bin/sh -c "
export VAULT_ADDR=$VAULT_ADDR

echo '1️⃣ Getting Kubernetes token...'
K8S_TOKEN=\$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

echo '2️⃣ Logging into Vault...'
VAULT_TOKEN=\$(vault write -field=token auth/kubernetes/login \
  role=nwl-wim-service \
  jwt=\$K8S_TOKEN)

echo '3️⃣ Reading secrets...'
export VAULT_TOKEN
vault kv get secret/$NAMESPACE/nwl-wim-service

echo ''
echo '✅ Vault access test successful!'
"
