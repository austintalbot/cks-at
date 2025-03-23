#!/bin/bash

echo "install kubecolor"

wget https://github.com/kubecolor/kubecolor/releases/download/v0.5.0/kubecolor_0.5.0_linux_amd64.tar.gz
tar -xvf kubecolor_0.5.0_linux_amd64.tar.gz
chmod +x kubecolor
sudo mv kubecolor /usr/local/bin/
rm kubecolor_0.5.0_linux_amd64.tar.gz



echo "install krew"
(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar zxvf "${KREW}.tar.gz" &&
  ./"${KREW}" install krew
)

export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

kubectl krew install cyclonus neat np-viewer sniff view-secret view-utilization view-webhook who-can
# Add Krew to PATH in .bashrc
echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >>~/.bashrc




echo "setup aliases and completion"

echo "source <(kubectl completion bash)" >>~/.bashrc
echo "source <(kubecolor completion bash)" >>~/.bashrc
echo "alias k=kubectl" >>~/.bashrc
echo "alias kubectl=kubecolor" >>~/.bashrc
echo "complete -o default -F __start_kubectl k" >>~/.bashrc

# Setup crictl completion
echo "source <(crictl completion bash)" >>~/.bashrc

# Setup podman completion
echo "source <(podman completion bash)" >>~/.bashrc
source ~/.bashrc

