#!/bin/bash

echo "🔄 Deleting Kind clusters..."
kind get clusters | xargs -t -n1 kind delete cluster --name 
echo "✅ Kind clusters deleted"
