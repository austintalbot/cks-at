#!/bin/bash
# Description: Test network connectivity between services in the cluster

# Function to test connectivity between source and target services
function test_connectivity() {
    local source=$1
    local target=$2
    local srcNamespace=$3
    local trgNamespace=$4

    # Test HTTP connectivity
    local result=$(kubectl -n $srcNamespace exec deployments/$source -- wget -qSO- --timeout=2 $target.$trgNamespace.svc.cluster.local 2>&1 | grep "HTTP/" | awk '{print $2}')
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        if [ "$result" == "200" ]; then
            echo -e "$(tput setaf 2)$source--> $target.$trgNamespace.svc.cluster.local: $result$(tput sgr0)"
        else
            echo -e "$(tput setaf 1)$source--> $target.$trgNamespace.svc.cluster.local: $result$(tput sgr0)"
        fi
    else
        echo -e "$(tput setaf 1)$source--> $target.$trgNamespace.svc.cluster.local: Connection failed$(tput sgr0)"
    fi

    # Test DNS resolution
    local dns_result=$(kubectl -n $srcNamespace exec deployments/$source -- nslookup -timeout=2 $target.$trgNamespace.svc.cluster.local)
    local dns_exit_code=$?

    if [ $dns_exit_code -eq 0 ]; then
        if [[ "$dns_result" == *"NXDOMAIN"* || "$dns_result" == *"server can't find"* ]]; then
            echo -e "$(tput setaf 1)\n$source--> nslookup $target.$trgNamespace.svc.cluster.local: $dns_result$(tput sgr0)"
        else
            echo -e "$(tput setaf 2)\n$source--> nslookup $target.$trgNamespace.svc.cluster.local: $dns_result$(tput sgr0)"
        fi
    else
        echo -e "$(tput setaf 1)\n$source--> nslookup $target.$trgNamespace.svc.cluster.local: DNS lookup failed$(tput sgr0)"
    fi
}

# Function to run connectivity tests for all services
function run_tests() {
    local services=("$@")
    for source in "${services[@]}"; do
        for target in "${services[@]}"; do
            local srcNamespace=$(detect_namespace $source)
            local trgNamespace=$(detect_namespace $target)
            test_connectivity $source $target $srcNamespace $trgNamespace &
        done
    done
    wait
}

# Function to detect the namespace of a service
function detect_namespace() {
    local service=$1
    if [[ "$service" == data-* || "$service" == processor-* ]]; then
        echo "data"
    else
        echo "app"
    fi
}

# Function to run DNS tests for all services
function run_dns_tests() {
    local services=("$@")
    for source in "${services[@]}"; do
        local srcNamespace=$(detect_namespace $source)
        test_connectivity $source kube-dns $srcNamespace kube-system &
    done
    wait
}

# Main script execution
echo -e "$(tput setaf 4)================================================================================$(tput sgr0)"
echo -e "$(tput setaf 4)connectivity and DNS should work$(tput sgr0)"
echo -e "$(tput setaf 4)================================================================================$(tput sgr0)"

services=("app1" "app2" "manager1" "manager2" "data-001" "data-002" "processor-a100" "processor-a200")
run_tests "${services[@]}"

echo -e "$(tput setaf 4)================================================================================$(tput sgr0)"
echo -e "$(tput setaf 4)connectivity should fail but DNS should work$(tput sgr0)"
echo -e "$(tput setaf 4)================================================================================$(tput sgr0)"

run_dns_tests "${services[@]}"

echo -e "$(tput setaf 4)================================================================================$(tput sgr0)"
echo -e "$(tput setaf 4)connectivity and DNS should fail$(tput sgr0)"
echo -e "$(tput setaf 4)================================================================================$(tput sgr0)"

test_connectivity app1 kube-proxy app kube-system
