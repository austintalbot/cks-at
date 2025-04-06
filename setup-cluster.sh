#!/bin/bash

NAME=$1
if [ -z "$NAME" ]; then
    echo "Usage: $0 <cluster-name>"
    exit 1
fi

echo "🔄 Creating Kind cluster '$NAME'..."
if ! kind get clusters | grep -q "$NAME"; then
    kind create cluster --name "$NAME" --config ./kind/kind.yaml
    echo "✅ Cluster '$NAME' created successfully"
else
    echo "ℹ️  Cluster '$NAME' already exists, skipping creation"
fi

echo "🔄 Installing Cilium CNI..."
helm upgrade --install cilium cilium/cilium \
    --namespace kube-system \
    --kube-context kind-"$NAME" \
    --set hubble.relay.enabled=true \
    --set hubble.ui.enabled=true \
    --set hubble.enabled=true \
    --set cluster.name="kind-$NAME" \
    --set cluster.id=1 \
    --set ipv4NativeRoutingCIDR=10.0.0.0/8 \
    --set clustermesh.enableEndpointSliceSynchronization=true 


cilium status 
echo "✅ Cilium installation complete"

echo "running the setup script on each node"
for node in $(kind get nodes --name "$NAME"); do
    echo "Running setup script on $node"
    docker cp set_etcd_and_kube_bench.sh "$node":/root/
    docker exec -it "$node" bash /root/set_etcd_and_kube_bench.sh
done