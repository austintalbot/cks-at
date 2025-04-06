#!/bin/bash

#set_etcd_and_kube_bench.sh

# Exit immediately if a command exits with a non-zero status
set -e

#!/bin/bash

export LC_ALL=C
install_kubecolor() {
  echo "Installing kubecolor..."
  OS="$(uname | tr '[:upper:]' '[:lower:]')"
  if [[ "$OS" == "darwin"* ]]; then
    echo "macOS detected, skipping kubecolor installation"
    return
  fi

  apt update -y
  apt install -y wget tar git bash-completion sudo file neovim
  apt upgrade -y

  #

  wget https://github.com/kubecolor/kubecolor/releases/download/v0.5.0/kubecolor_0.5.0_linux_amd64.tar.gz
  tar -xvf kubecolor_0.5.0_linux_amd64.tar.gz
  chmod +x kubecolor
  sudo mv kubecolor /usr/local/bin/
  rm kubecolor_0.5.0_linux_amd64.tar.gz
}

install_krew() {
  # don't fail here
  set +e

  echo "Installing krew..."
  (
    set -x
    OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
      ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
      KREW="krew-${OS}_${ARCH}" &&
      curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
      tar zxvf "${KREW}.tar.gz" &&
      chmod +x "${KREW}" && # Add executable permissions
      ./"${KREW}" install krew
  )

  export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
  kubectl krew install cyclonus neat np-viewer sniff view-secret view-utilization view-webhook who-can

  # Add Krew to PATH in .bashrc if not already present
  if ! grep -q 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' ~/.bashrc; then
    echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >>~/.bashrc
  fi
}

install_yq() {
  echo "Installing yq..."
  wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
  chmod +x /usr/bin/yq
}
setup_aliases_and_completion() {
  echo "Setting up aliases and completion..."

  # Ensure bash-completion is sourced
  if ! grep -q '/usr/share/bash-completion/bash_completion' ~/.bashrc; then
    echo 'if [ -f /usr/share/bash-completion/bash_completion ]; then' >>~/.bashrc
    echo '    . /usr/share/bash-completion/bash_completion' >>~/.bashrc
    echo 'fi' >>~/.bashrc

    # Check if kubectl completion is already set u
    echo "source /usr/share/bash-completion/bash_completion" >>~/.bashrc
    echo 'complete -o default -F __start_kubectl k' >>~/.bashrc

  fi

  # Add kubectl completion
  if ! grep -q 'source <(kubectl completion bash)' ~/.bashrc; then
    echo "source <(kubectl completion bash)" >>~/.bashrc
  fi

  # Add kubecolor completion
  if ! grep -q 'source <(kubecolor completion bash)' ~/.bashrc; then
    echo "source <(kubecolor completion bash)" >>~/.bashrc
  fi

  # Add alias for kubectl
  if ! grep -q 'alias k=kubectl' ~/.bashrc; then
    echo "alias k=kubectl" >>~/.bashrc
  fi

  # Add alias for kubectl to kubecolor
  if ! grep -q 'alias kubectl=kubecolor' ~/.bashrc; then
    echo "alias kubectl=kubecolor" >>~/.bashrc
  fi

  # Add kubectl completion for alias 'k'
  if ! grep -q 'complete -o default -F __start_kubectl k' ~/.bashrc; then
    echo "complete -o default -F __start_kubectl k" >>~/.bashrc
  fi

  # Add crictl completion
  if ! grep -q 'source <(crictl completion bash)' ~/.bashrc; then
    echo "source <(crictl completion bash)" >>~/.bashrc
  fi

  # Reload .bashrc to apply changes
  source ~/.bashrc
}

main() {
  install_kubecolor
  install_krew
  install_yq
  setup_aliases_and_completion
}

main

# Function to check the exit status of the last command
check_status() {
  if [ $? -ne 0 ]; then
    echo "Error: $1 failed. Exiting."
    exit 1
  fi
}

# Get the latest kube-bench version
version=$(curl -Ls -o /dev/null -w %{url_effective} https://github.com/aquasecurity/kube-bench/releases/latest)
export KUBE_BENCH_VERSION=$(echo $version | grep -oP '(?<=/)[^/]+$')
export KUBE_BENCH_VERSION_NUMBER=$(echo $KUBE_BENCH_VERSION | cut -d'v' -f2)
echo "Detected KUBE_BENCH_VERSION: $KUBE_BENCH_VERSION"

export KUBERNETES_VERSION=$(kubectl version -o yaml | yq .serverVersion.gitVersion | cut -d'v' -f2 | cut -d'.' -f1,2)
# Determine the processor architecture
export arch=$(uname -m)
if [[ $arch == "aarch64" ]]; then
  echo "Running on aarch64 architecture. arm64 detected."
  export processor="arm64"
elif [[ $arch == "x86_64" ]]; then
  echo "Running on x86_64 architecture. amd64 detected."
  export processor="amd64"
else
  echo "Unsupported architecture: $arch. Exiting."
  exit 1
fi

# Function to install kube-bench if not installed
install_kube_bench() {
  if ! command -v kube-bench >/dev/null; then
    echo "kube-bench is not installed. Installing..."
    echo "Downloading kube-bench version ${KUBE_BENCH_VERSION}..."
    echo "curl command:"
    echo "https://github.com/aquasecurity/kube-bench/releases/download/${KUBE_BENCH_VERSION}/kube-bench_${KUBE_BENCH_VERSION_NUMBER}_linux_${processor}.deb"
    curl -L "https://github.com/aquasecurity/kube-bench/releases/download/${KUBE_BENCH_VERSION}/kube-bench_${KUBE_BENCH_VERSION_NUMBER}_linux_${processor}.deb" -o "kube-bench_${KUBE_BENCH_VERSION}_linux_${processor}.deb"

    chmod 644 "kube-bench_${KUBE_BENCH_VERSION}_linux_${processor}.deb"
    # Check if the file was downloaded successfully
    if [ ! -s "kube-bench_${KUBE_BENCH_VERSION}_linux_${processor}.deb" ]; then
      echo "Error: Failed to download the .deb file. Exiting."
      exit 1
    fi

    echo "Validating the downloaded file..."
    if ! file "kube-bench_${KUBE_BENCH_VERSION}_linux_${processor}.deb" | grep -q "Debian binary package"; then
      echo "Error: The downloaded file is not a valid .deb package. Exiting."
      exit 1
    fi

    echo "Installing kube-bench..."
    sudo apt install "./kube-bench_${KUBE_BENCH_VERSION}_linux_${processor}.deb" -f
    check_status "kube-bench installation"
    echo "kube-bench installed successfully."
  else
    echo "kube-bench is already installed. Skipping installation."
  fi
}

# Step 1: Create a system group for etcd if it doesn't already exist
echo "Checking if group 'etcd' exists..."
if ! getent group etcd >/dev/null; then
  echo "Creating system group 'etcd'..."
  sudo groupadd --system etcd
  check_status "Group creation"
else
  echo "Group 'etcd' already exists. Skipping."
fi

# Step 2: Create a system user for etcd if it doesn't already exist
echo "Checking if user 'etcd' exists..."
if ! id -u etcd >/dev/null 2>&1; then
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

# restart the shell so that kube-bench is part of the path

echo "Reloading shell environment to update PATH..."
source ~/.bashrc

# Step 5: Run kube-bench for master node checks
echo "Running kube-bench for master node checks..."
kube-bench run --targets=master --nosummary --version $KUBERNETES_VERSION
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
  kube-bench run --check "$check" --nosummary --version $KUBERNETES_VERSION
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
kube-bench run --targets=master --nosummary --version $KUBERNETES_VERSION | grep -i fail || echo "No failures found."
check_status "Final kube-bench master node check"

main() {
  install_kubecolor
  install_krew
  install_yq
  setup_aliases_and_completion
  source ~/.bashrc
  echo "Script completed successfully!"

}

main
