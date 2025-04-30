#!/bin/bash
################# LFS260:2025-02-14 s_04/k8scp.sh ################
# The code herein is: Copyright The Linux Foundation, 2025
#
# This Copyright is retained for the purpose of protecting free
# redistribution of source.
#
#     URL:    https://training.linuxfoundation.org
#     email:  info@linuxfoundation.org
#
# This code is distributed under Version 2 of the GNU General Public
# License, which you should have received with the source.
## TxS 03-2022
echo "This script is written to work with Ubuntu 20.04"
sleep 3
echo
echo "Disable swap until next reboot"
echo
sudo swapoff -a

echo "Updating the local node, please stand-by"
sudo apt-get update && sudo apt-get upgrade -y
echo

echo "Ensure two modules are loaded after reboot"

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sleep 2

echo "Load the modules now"

sudo modprobe overlay

sudo modprobe br_netfilter

sleep 2

echo "Update sysctl to load iptables and ipforwarding"

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system


sleep 2
echo "Install some necessary software"
sudo apt-get install curl apt-transport-https vim git wget gnupg2 software-properties-common lsb-release ca-certificates uidmap socat -y

sleep 2

echo "Install and configure containerd"
sleep 2

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update &&  sudo apt-get install containerd.io
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl daemon-reload
sudo systemctl enable --now containerd
sudo systemctl restart containerd


echo
echo "Install kubeadm, kubelet, and kubectl"
sleep 2

sudo mkdir -m 755 -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update

sudo apt-get install -y kubeadm=1.32.1-1.1 kubelet=1.32.1-1.1 kubectl=1.32.1-1.1

sudo apt-mark hold kubelet kubeadm kubectl


## If you are going to use a different plugin you'll want
## to use a different IP address, found in that plugins
## readme file.

sleep 3

## This assumes you are not using 10.0.0.0/8 for your host. If your node network is in the same range you will lose connectivity to other nodes.
#sudo kubeadm init  | sudo tee /var/log/kubeinit.log
sudo kubeadm init --kubernetes-version=1.32.1 --pod-network-cidr=10.0.0.0/8 | sudo tee /var/log/kubeinit.log
sleep 15

echo "Running the steps explained at the end of the init output for you"

mkdir -p $HOME/.kube

sleep 2

sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

sleep 2

sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "Apply Calico network plugin from ProjectCalico.org"
echo "If you see an error they may have updated the yaml file. Use a browser, navigate to the site and find the updated file "
echo
echo

# Use Cilium as the network plugin
# Install the CLI first
export CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/master/stable.txt)
export CLI_ARCH=amd64

# Ensure correct architecture
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

# Make sure download worked
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum

# Move binary to correct location and remove tarball
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

# Now that binary is in place, install network plugin
echo '********************************************************'
echo '********************************************************'
echo
echo Installing Cilium, this may take a bit...
echo
echo '********************************************************'
echo '********************************************************'
echo

cilium install

echo
sleep 3
echo Cilium install finished. Continuing with script.
echo



#kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml

echo
echo
sleep 15
echo "You should see this node in the output below"
echo "It can take up to a minute for node to show Ready status"
echo
kubectl get node
echo
# Get crictl configured for later use.
cat <<EOF | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 5
debug: false
EOF


# Add Helm to make our life easier
wget https://get.helm.sh/helm-v3.11.1-linux-amd64.tar.gz
tar -xf helm-v3.11.1-linux-amd64.tar.gz
sudo cp linux-amd64/helm /usr/local/bin/
sleep 15

echo
echo "Script finished. Move to the next step"
