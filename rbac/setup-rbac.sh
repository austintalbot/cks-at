#!/bin/bash

# Set namespace
NAMESPACE="rbac-system"

# Create namespace
kubectl create namespace "$NAMESPACE" -o yaml | tee namespace.yaml | yq

# Create service account
kubectl create serviceaccount rbac-admin -n "$NAMESPACE" -o yaml | tee serviceaccount.yaml | yq

# Create cluster role
kubectl create clusterrole rbac-admin \
  --verb=get,list,watch,create,update,patch,delete \
  --resource=pods,pods/log,pods/exec,configmaps,secrets,serviceaccounts \
  -o yaml | tee clusterrole.yaml | yq

# Create cluster role binding
kubectl create clusterrolebinding rbac-admin-binding \
  --clusterrole=rbac-admin \
  --serviceaccount="$NAMESPACE:rbac-admin" \
  -o yaml | tee clusterrolebinding.yaml | yq

# Define namespaces for role and role binding creation
NAMESPACES=("rbac-system" "kube-system" "kube-public" "kube-node-lease")

# Loop through namespaces to create roles and role bindings
for ns in "${NAMESPACES[@]}"; do
  # Create role
  kubectl create role rbac-admin \
    --verb=get,list,watch,create,update,patch,delete \
    --resource=pods,pods/log,pods/exec,configmaps,secrets,serviceaccounts \
    -n "$ns" -o yaml | tee "role-$ns.yaml" | yq

  # Create role binding
  kubectl create rolebinding rbac-admin-binding \
    --role=rbac-admin \
    --serviceaccount="$NAMESPACE:rbac-admin" \
    -n "$ns" -o yaml | tee "rolebinding-$ns.yaml" | yq
done