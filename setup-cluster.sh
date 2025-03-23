#!/bin/bash

echo "🔄 Creating Kind cluster 'test'..."
if ! kind get clusters | grep -q test; then
    kind create cluster --name test --config ./kind/kind.config
    echo "✅ Cluster 'test' created successfully"
else
    echo "ℹ️  Cluster 'test' already exists, skipping creation"
fi

echo "🔄 Installing Cilium CNI..."
helm upgrade --install cilium cilium/cilium \
    --namespace kube-system \
    --kube-context kind-test \
    --set hubble.relay.enabled=true \
    --set hubble.ui.enabled=true \
    --set hubble.enabled=true \
    --set cluster.name=test \
    --set cluster.id=1 \
    --set ipv4NativeRoutingCIDR=10.0.0.0/8 \
    --set clustermesh.enableEndpointSliceSynchronization=true \
    --wait
echo "✅ Cilium installation complete"
