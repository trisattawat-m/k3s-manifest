#!/bin/sh
kubectl apply -f namespaces/
kubectl apply -f serviceaccounts/
kubectl apply -f apps/nwl-wim-service/
