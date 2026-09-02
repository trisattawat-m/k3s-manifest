path "network-link/data/{{identity.entity.aliases.auth_kubernetes.metadata.service_account_namespace}}/{{identity.entity.aliases.auth_kubernetes.metadata.service_account_name}}/*" {
  capabilities = ["read", "list"]
}

path "network-link/metadata/{{identity.entity.aliases.auth_kubernetes.metadata.service_account_namespace}}/{{identity.entity.aliases.auth_kubernetes.metadata.service_account_name}}/*" {
  capabilities = ["list"]
}
