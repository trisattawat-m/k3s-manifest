# Vault policy for nwl-wim-service
path "network-link/data/dev/nwl-wim-service" {
  capabilities = ["read", "create", "update"]
}

path "network-link/data/test/nwl-wim-service" {
  capabilities = ["read", "create", "update"]
}

path "network-link/metadata/dev/nwl-wim-service" {
  capabilities = ["list", "read"]
}

path "network-link/metadata/test/nwl-wim-service" {
  capabilities = ["list", "read"]
}

path "auth/token/renew-self" {
  capabilities = ["update"]
}

path "auth/token/lookup-self" {
  capabilities = ["read"]
}
