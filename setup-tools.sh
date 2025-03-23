#!/bin/bash

echo "install kubecolor"

wget https://github.com/kubecolor/kubecolor/releases/download/v0.5.0/kubecolor_0.5.0_linux_amd64.tar.gz
tar -xvf kubecolor_0.5.0_linux_amd64.tar.gz
chmod +x kubecolor
sudo mv kubecolor /usr/local/bin/
rm kubecolor_0.5.0_linux_amd64.tar.gz

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

