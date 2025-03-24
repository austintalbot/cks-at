#!/bin/bash

# Delete deployments in the 'app' namespace
kubecolor delete deployment app1 -n app
kubecolor delete deployment app2 -n app
kubecolor delete deployment manager1 -n app
kubecolor delete deployment manager2 -n app

# Delete services in the 'app' namespace
kubecolor delete service app1 -n app
kubecolor delete service app2 -n app
kubecolor delete service manager1 -n app
kubecolor delete service manager2 -n app

kubecolor delete -f netpol-app.yaml

# Delete the 'app' namespace
kubecolor delete ns app

# Delete deployments in the 'data' namespace
kubecolor delete deployment data-001 -n data
kubecolor delete deployment data-002 -n data
kubecolor delete deployment processor-a100 -n data
kubecolor delete deployment processor-a200 -n data

# Delete services in the 'data' namespace
kubecolor delete service data-001 -n data
kubecolor delete service data-002 -n data
kubecolor delete service processor-a100 -n data
kubecolor delete service processor-a200 -n data

kubecolor delete -f netpol-data.yaml

# Delete the 'data' namespace
kubecolor delete ns data