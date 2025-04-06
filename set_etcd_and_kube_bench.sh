#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

export LC_ALL=C

# Function to install kubecolor
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

  wget https://github.com/kubecolor/kubecolor/releases/download/v0.5.0/kubecolor_0.5.0_linux_amd64.tar.gz
  tar -xvf kubecolor_0.5.0_linux_amd64.tar.gz
  chmod +x kubecolor
  sudo mv kubecolor /usr/local/bin/
  rm kubecolor_0.5.0_linux_amd64.tar.gz
}

# Function to install krew
install_krew() {
  set +e
  echo "Installing krew..."
  (
    set -x
    OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
      ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
      KREW="krew-${OS}_${ARCH}" &&
      curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
      tar zxvf "${KREW}.tar.gz" &&
      chmod +x "${KREW}" &&
      ./"${KREW}" install krew
  )

  export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
  kubectl krew install cyclonus neat np-viewer sniff view-secret view-utilization view-webhook who-can

  if ! grep -q 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' ~/.bashrc; then
    echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >>~/.bashrc
  fi
}

# Function to install yq
install_yq() {
  echo "Installing yq..."
  wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
  chmod +x /usr/bin/yq
}

# Function to set up aliases and completion
setup_aliases_and_completion() {
  echo "Setting up aliases and completion..."
  if ! grep -q '/usr/share/bash-completion/bash_completion' ~/.bashrc; then
    echo 'if [ -f /usr/share/bash-completion/bash_completion ]; then' >>~/.bashrc
    echo '    . /usr/share/bash-completion/bash_completion' >>~/.bashrc
    echo 'fi' >>~/.bashrc
  fi

  if ! grep -q 'source <(kubectl completion bash)' ~/.bashrc; then
    echo "source <(kubectl completion bash)" >>~/.bashrc
  fi

  if ! grep -q 'alias k=kubectl' ~/.bashrc; then
    echo "alias k=kubectl" >>~/.bashrc
  fi

  if ! grep -q 'alias kubectl=kubecolor' ~/.bashrc; then
    echo "alias kubectl=kubecolor" >>~/.bashrc
  fi

  if ! grep -q 'complete -o default -F __start_kubectl k' ~/.bashrc; then
    echo "complete -o default -F __start_kubectl k" >>~/.bashrc
  fi

  source ~/.bashrc
}

# Function to install kube-bench
install_kube_bench() {
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

  if ! command -v kube-bench >/dev/null; then
    echo "Installing kube-bench..."
    curl -L "https://github.com/aquasecurity/kube-bench/releases/download/${KUBE_BENCH_VERSION}/kube-bench_${KUBE_BENCH_VERSION_NUMBER}_linux_${processor}.deb" -o "kube-bench_${KUBE_BENCH_VERSION}_linux_${processor}.deb"
    chmod 644 "kube-bench_${KUBE_BENCH_VERSION}_linux_${processor}.deb"
    sudo apt install "./kube-bench_${KUBE_BENCH_VERSION}_linux_${processor}.deb" -f
  else
    echo "kube-bench is already installed."
  fi
}

# Function to set up etcd user and group
setup_etcd_user_and_group() {
  echo "Setting up etcd user and group..."
  if ! getent group etcd >/dev/null; then
    sudo groupadd --system etcd
  fi

  if ! id -u etcd >/dev/null 2>&1; then
    sudo useradd -s /sbin/nologin --system -g etcd etcd
  fi

  sudo chown -R etcd:etcd /var/lib/etcd/
}

# Function to run kube-bench checks
run_kube_bench_checks() {
  echo "Running kube-bench checks..."
  kube-bench run --targets=master --nosummary --version $KUBERNETES_VERSION
  kube-bench run --targets=master | grep -i fail || echo "No failures found."
  for check in 1.2.5 1.2.16 1.2.17 1.2.18 1.2.19; do
    kube-bench run --check "$check" --nosummary --version $KUBERNETES_VERSION
  done
}

# Function to secure Kubernetes PKI certificates
secure_kubernetes_pki() {
  echo "Securing Kubernetes PKI certificates..."
  if [ -d /etc/kubernetes/pki ]; then
    chmod -R 600 /etc/kubernetes/pki/*.crt
  fi
}

# Function to verify kube-apiserver.yaml
verify_kube_apiserver_yaml() {
  echo "Verifying kube-apiserver.yaml..."
  if [ -f /etc/kubernetes/manifests/kube-apiserver.yaml ]; then
    grep ubelet-certificate-authority /etc/kubernetes/manifests/kube-apiserver.yaml || echo "No matches found."
  fi
}

# Main function
main() {
  install_kubecolor
  install_krew
  install_yq
  setup_aliases_and_completion
  setup_etcd_user_and_group
  install_kube_bench
  secure_kubernetes_pki
  run_kube_bench_checks
  verify_kube_apiserver_yaml
  echo "Script completed successfully!"
  source ~/.bashrc
  env | sort
  pushd /etc/kubernetes/manifests
  kube-bench run --targets=master --version 1.32
  popd

}

main
