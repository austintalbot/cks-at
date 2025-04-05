#!/bin/bash

#set_etcd_and_kube_bench.sh

# Exit immediately if a command exits with a non-zero status
set -e

# Function to check the exit status of the last command
check_status() {
  if [ $? -ne 0 ]; then
    echo "Error: $1 failed. Exiting."
    exit 1
  fi
}

# Function to install kube-bench if not installed
install_kube_bench() {
  if ! command -v kube-bench > /dev/null; then
    echo "kube-bench is not installed. Installing..."
    # Example installation command for kube-bench (adjust based on your system)
    curl -L https://github.com/aquasecurity/kube-bench/releases/latest/download/kube-bench_$(uname -s)_$(uname -m) -o /usr/local/bin/kube-bench
    sudo chmod +x /usr/local/bin/kube-bench
    check_status "kube-bench installation"
    echo "kube-bench installed successfully."
  else
    echo "kube-bench is already installed. Skipping installation."
  fi
}

# Step 1: Create a system group for etcd if it doesn't already exist
echo "Checking if group 'etcd' exists..."
if ! getent group etcd > /dev/null; then
  echo "Creating system group 'etcd'..."
  sudo groupadd --system etcd
  check_status "Group creation"
else
  echo "Group 'etcd' already exists. Skipping."
fi

# Step 2: Create a system user for etcd if it doesn't already exist
echo "Checking if user 'etcd' exists..."
if ! id -u etcd > /dev/null 2>&1; then
  echo "Creating system user 'etcd'..."
  sudo useradd -s /sbin/nologin --system -g etcd etcd
  check_status "User creation"
else
  echo "User 'etcd' already exists. Skipping."
fi

# Step 3: Change ownership of the etcd data directory
echo "Changing ownership of /var/lib/etcd/ to etcd:etcd..."
sudo chown -R etcd:etcd /var/lib/etcd/
check_status "Ownership change"

# Step 4: Ensure kube-bench is installed
install_kube_bench

# Step 5: Run kube-bench for master node checks
echo "Running kube-bench for master node checks..."
kube-bench run --targets=master
check_status "kube-bench master node check"

# Step 6: Secure Kubernetes PKI certificates
echo "Securing Kubernetes PKI certificates..."
if [ -d /etc/kubernetes/pki ]; then
  chmod -R 600 /etc/kubernetes/pki/*.crt
  check_status "PKI certificate permissions update"
else
  echo "/etc/kubernetes/pki directory does not exist. Skipping."
fi

# Step 7: Run kube-bench and filter for failed checks
echo "Running kube-bench and filtering for failed checks..."
kube-bench run --targets=master | grep -i fail || echo "No failures found."

# Step 8: Run specific kube-bench checks
echo "Running specific kube-bench checks..."
for check in 1.2.5 1.2.16 1.2.17 1.2.18 1.2.19; do
  kube-bench run --check "$check" --nosummary
  check_status "kube-bench check $check"
done

# Step 9: Verify kube-apiserver.yaml configuration
echo "Verifying kube-apiserver.yaml configuration..."
if [ -f /etc/kubernetes/manifests/kube-apiserver.yaml ]; then
  grep ubelet-certificate-authority /etc/kubernetes/manifests/kube-apiserver.yaml || echo "No matches found."
else
  echo "/etc/kubernetes/manifests/kube-apiserver.yaml does not exist. Skipping."
fi

# Step 10: Copy kube-apiserver.yaml to the manifests directory
echo "Copying kube-apiserver.yaml to /etc/kubernetes/manifests/..."
if [ -f kube-apiserver.yaml ]; then
  cp kube-apiserver.yaml /etc/kubernetes/manifests/ -v
  check_status "Copy kube-apiserver.yaml"
else
  echo "kube-apiserver.yaml file does not exist in the current directory. Skipping."
fi

# Step 11: Create a directory for audit logs
echo "Creating directory for audit logs..."
mkdir -p /var/log/apiserver/audit.log
check_status "Audit log directory creation"

# Final Step: Run kube-bench for master node checks again
echo "Running kube-bench for master node checks again..."
kube-bench run --targets=master --nosummary | grep -i fail || echo "No failures found."
check_status "Final kube-bench master node check"

echo "Script completed successfully!"