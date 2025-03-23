#!/bin/bash
# Description: Test network connectivity between services in the cluster
function test_connectivity() {
    local source=$1
    local target=$2
    local namespace=$3
    local target_namespace=$4
    local result=$(kubecolor -n $namespace exec deployments/$source -- wget -qSO- --timeout=1 $target.$target_namespace.svc.cluster.local 2>&1 | grep "HTTP/" | awk '{print $2}')
    if [ "$result" == "200" ]; then
        echo -e "\e[32m$source--> $target.$target_namespace.svc.cluster.local: $result\e[0m" | column -t
    else
        echo -e "\e[31m$source--> $target.$target_namespace.svc.cluster.local: $result\e[0m" | column -t
    fi
}

echo "testing network connectivity"

echo "==========================="
echo "app1 -> app2, manager1, manager2, data-001, data-002, processor-a100, processor-a200"
test_connectivity app1 app2 app app
test_connectivity app1 manager1 app app
test_connectivity app1 manager2 app app
test_connectivity app1 data-001 app data
test_connectivity app1 data-002 app data
test_connectivity app1 processor-a100 app data
test_connectivity app1 processor-a200 app data

echo "==========================="
echo "app2 -> app1, manager1, manager2, data-001, data-002, processor-a100, processor-a200"
test_connectivity app2 app1 app app
test_connectivity app2 manager1 app app
test_connectivity app2 manager2 app app
test_connectivity app2 data-001 app data
test_connectivity app2 data-002 app data
test_connectivity app2 processor-a100 app data
test_connectivity app2 processor-a200 app data

echo "==========================="
echo "manager1 -> app1, app2, manager2, data-001, data-002, processor-a100, processor-a200"
test_connectivity manager1 app1 app app
test_connectivity manager1 app2 app app
test_connectivity manager1 manager2 app app
test_connectivity manager1 data-001 app data
test_connectivity manager1 data-002 app data
test_connectivity manager1 processor-a100 app data
test_connectivity manager1 processor-a200 app data

echo "==========================="
echo "manager2 -> app1, app2, manager1, data-001, data-002, processor-a100, processor-a200"

test_connectivity manager2 app1 app app
test_connectivity manager2 app2 app app 
test_connectivity manager2 manager1 app app
test_connectivity manager2 data-001 app data
test_connectivity manager2 data-002 app data
test_connectivity manager2 processor-a100 app data
test_connectivity manager2 processor-a200 app data


echo "==========================="
echo "data-001 -> app1, app2, manager1, manager2, data-002, processor-a100, processor-a200"
test_connectivity data-001 app1 data app
test_connectivity data-001 app2 data app 
test_connectivity data-001 manager1 data app
test_connectivity data-001 manager2 data app
test_connectivity data-001 data-002 data data
test_connectivity data-001 processor-a100 data data
test_connectivity data-001 processor-a200 data data

echo "==========================="
echo "data-002 -> app1, app2, manager1, manager2, data-001, processor-a100, processor-a200"
test_connectivity data-002 app1 data app
test_connectivity data-002 app2 data app
test_connectivity data-002 manager1 data app
test_connectivity data-002 manager2 data app
test_connectivity data-002 data-001 data data
test_connectivity data-002 processor-a100 data data
test_connectivity data-002 processor-a200 data data

echo "==========================="
echo "processor-a100 -> app1, app2, manager1, manager2, data-001, data-002, processor-a200"
test_connectivity processor-a100 app1 data app
test_connectivity processor-a100 app2 data app
test_connectivity processor-a100 manager1 data app
test_connectivity processor-a100 manager2 data app
test_connectivity processor-a100 data-001 data data
test_connectivity processor-a100 data-002 data data
test_connectivity processor-a100 processor-a200 data data

echo "==========================="
echo "processor-a200 -> app1, app2, manager1, manager2, data-001, data-002, processor-a100"
test_connectivity processor-a200 app1 data app
test_connectivity processor-a200 app2 data app
test_connectivity processor-a200 manager1 data app
test_connectivity processor-a200 manager2 data app
test_connectivity processor-a200 data-001 data data
test_connectivity processor-a200 data-002 data data
test_connectivity processor-a200 processor-a100 data data