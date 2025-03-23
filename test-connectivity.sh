#!/bin/bash
# Description: Test network connectivity between services in the cluster
function test_connectivity() {
    local source=$1
    local target=$2
    local namespace=$3
    local target_namespace=$4

    local result=$(kubecolor -n $namespace exec deployments/$source -- wget -qSO- --timeout=1 $target.$target_namespace.svc.cluster.local 2>&1 | grep "HTTP/" | awk '{print $2}')
    if [ "$result" == "200" ]; then
        echo -e "$(tput setaf 2)$source--> $target.$target_namespace.svc.cluster.local: $result$(tput sgr0)" | column -t
    else
        echo -e "$(tput setaf 1)$source--> $target.$target_namespace.svc.cluster.local: $result$(tput sgr0)" | column -t
    fi

    local dns_result=$(kubecolor -n $namespace exec deployments/$source -- nslookup -timeout=2 $target.$target_namespace.svc.cluster.local)
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        if [[ "$dns_result" == *"NXDOMAIN"* || "$dns_result" == *"server can't find"* ]]; then
            echo -e "$(tput setaf 1)\n$source--> nslookup $target.$target_namespace.svc.cluster.local: $dns_result$(tput sgr0)" | column -t
        else
            echo -e "$(tput setaf 2)\n$source--> nslookup $target.$target_namespace.svc.cluster.local: $dns_result$(tput sgr0)" | column -t
        fi
    else
        echo -e "$(tput setaf 1)\n$source--> nslookup $target.$target_namespace.svc.cluster.local: DNS lookup failed$(tput sgr0)" | column -t
    fi
}

echo "================================================================================="
echo "connectivity should and DNS should work"
echo "================================================================================="

test_connectivity app1 app2 app app &
test_connectivity app1 manager1 app app &
test_connectivity app1 manager2 app app &
test_connectivity app1 data-001 app data &
test_connectivity app1 data-002 app data &
test_connectivity app1 processor-a100 app data &
test_connectivity app1 processor-a200 app data &


test_connectivity app2 app1 app app &
test_connectivity app2 manager1 app app &
test_connectivity app2 manager2 app app &
test_connectivity app2 data-001 app data &
test_connectivity app2 data-002 app data &
test_connectivity app2 processor-a100 app data &
test_connectivity app2 processor-a200 app data &


test_connectivity manager1 app1 app app &
test_connectivity manager1 app2 app app &
test_connectivity manager1 manager2 app app &
test_connectivity manager1 data-001 app data &
test_connectivity manager1 data-002 app data &
test_connectivity manager1 processor-a100 app data &
test_connectivity manager1 processor-a200 app data &


test_connectivity manager2 app1 app app &
test_connectivity manager2 app2 app app &
test_connectivity manager2 manager1 app app &
test_connectivity manager2 data-001 app data &
test_connectivity manager2 data-002 app data &
test_connectivity manager2 processor-a100 app data &
test_connectivity manager2 processor-a200 app data &


test_connectivity data-001 app1 data app &
test_connectivity data-001 app2 data app &
test_connectivity data-001 manager1 data app &
test_connectivity data-001 manager2 data app &
test_connectivity data-001 data-002 data data &
test_connectivity data-001 processor-a100 data data &
test_connectivity data-001 processor-a200 data data &


test_connectivity data-002 app1 data app &
test_connectivity data-002 app2 data app &
test_connectivity data-002 manager1 data app &
test_connectivity data-002 manager2 data app &
test_connectivity data-002 data-001 data data &
test_connectivity data-002 processor-a100 data data &
test_connectivity data-002 processor-a200 data data &


test_connectivity processor-a100 app1 data app &
test_connectivity processor-a100 app2 data app &
test_connectivity processor-a100 manager1 data app &
test_connectivity processor-a100 manager2 data app &
test_connectivity processor-a100 data-001 data data &
test_connectivity processor-a100 data-002 data data &
test_connectivity processor-a100 processor-a200 data data &


test_connectivity processor-a200 app1 data app &
test_connectivity processor-a200 app2 data app &
test_connectivity processor-a200 manager1 data app &
test_connectivity processor-a200 manager2 data app &
test_connectivity processor-a200 data-001 data data &
test_connectivity processor-a200 data-002 data data &
test_connectivity processor-a200 processor-a100 data data &
wait

echo "================================================================================="
echo "connectivity should fail but DNS should work"
echo "================================================================================="

test_connectivity app1 kube-dns app kube-system &
test_connectivity app2 kube-dns app kube-system &
test_connectivity manager1 kube-dns app kube-system &
test_connectivity manager2 kube-dns app kube-system &
test_connectivity data-001 kube-dns data kube-system &
test_connectivity data-002 kube-dns data kube-system &
test_connectivity processor-a100 kube-dns data kube-system &
test_connectivity processor-a200 kube-dns data kube-system &
wait

echo "================================================================================="
echo "connectivity and DNS should fail "
echo "================================================================================="

test_connectivity app1 kube-proxy app kube-system
