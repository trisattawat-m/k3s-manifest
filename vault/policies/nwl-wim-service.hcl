# ============================================================================
# File: vault/policies/nwl-wim-service.hcl
# Description: Vault policy for nwl-wim-service
# ============================================================================
# Path: secret/data/dev/nwl-wim-service
path "secret/data/dev/nwl-wim-service" {
  capabilities = ["read", "create", "update"]
}

# Path: secret/data/test/nwl-wim-service
path "secret/data/test/nwl-wim-service" {
  capabilities = ["read", "create", "update"]
}

# Allow listing secrets (optional but useful)
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