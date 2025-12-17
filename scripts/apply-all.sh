# Create directory structure
mkdir -p ~/k3s-manifest/{namespaces,apps/{nwl-wim-service,vault},monitoring/grafana,ingress}

# Apply namespaces first
kubectl apply -f namespaces/

# Apply ingress configuration
kubectl apply -f ingress/

# Apply apps
kubectl apply -f apps/nwl-wim-service/
kubectl apply -f apps/vault/

# Apply monitoring
kubectl apply -f monitoring/grafana/

# Check status
kubectl get all -n dev
kubectl get all -n monitoring
kubectl get ingress -A
