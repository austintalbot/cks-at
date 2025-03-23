#!/bin/bash

kubecolor create ns app || true
kubecolor create deployment app1 --image=nginx:alpine -n app
kubecolor create deployment app2 --image=nginx:alpine -n app
kubecolor create deployment manager1 --image=nginx:alpine -n app
kubecolor create deployment manager2 --image=nginx:alpine -n app

kubecolor expose deployment app1 --port=80 --target-port=80 -n app
kubecolor expose deployment app2 --port=80 --target-port=80 -n app
kubecolor expose deployment manager1 --port=80 --target-port=80 -n app
kubecolor expose deployment manager2 --port=80 --target-port=80 -n app

kubecolor create ns data || true
kubecolor create deployment data-001 --image=nginx:alpine -n data
kubecolor create deployment data-002 --image=nginx:alpine -n data
kubecolor create deployment processor-a100 --image=nginx:alpine -n data
kubecolor create deployment processor-a200 --image=nginx:alpine -n data

kubecolor expose deployment data-001 --port=80 --target-port=80 -n data
kubecolor expose deployment data-002 --port=80 --target-port=80 -n data
kubecolor expose deployment processor-a100 --port=80 --target-port=80 -n data
kubecolor expose deployment processor-a200 --port=80 --target-port=80 -n data

kubecolor wait -n app --for=condition=available deployment --all --timeout=30s
kubecolor wait -n data --for=condition=available deployment --all --timeout=30s

echo
echo Pods in Namespace app
kubecolor -n app get pod -o wide --show-labels | sed 's/NOMINATED NODE/NOMINATED_NODE/g' | sed 's/READINESS GATES/READINESS_GATES/g' | awk '{print $1,$3,$5,$6,$10}' | column -t

echo
echo Pods in Namespace data
kubecolor -n data get pod -o wide --show-labels | sed 's/NOMINATED NODE/NOMINATED_NODE/g' | sed 's/READINESS GATES/READINESS_GATES/g' | awk '{print $1,$3,$5,$6,$10}' | column -t

