#!/bin/bash
################# LFS260:2025-02-14 s_04/installScripts/install-2Node-crio-cluster.sh ################
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

# A script to install two node cluster running crio
# Pass the IPs of the cp then the worker node to after this script
# Something like: install-2Node-crio-cluster.sh <cpIP> <workerIP>
# Created by Tim Serewicz for The Linux Foundation, 06/2021.  GPL

# Edit for your particular PEM key and or non-root user
export PEM=$HOME/LF-Class.pem
export user=student

# Master: Download tar ball and expand
ssh -oStrictHostKeyChecking=no -i $PEM $user@$1 'wget https://cm.lf.training/LFS460/LFS460_V1.21.1_SOLUTIONS.tar.xz --user=LFtraining --password=Penguin2014'

ssh -i $PEM $user@$1 'tar -xvf LFS460_V1.21.1_SOLUTIONS.tar.xz'

# Run the cp setup script
ssh -i $PEM $user@$1 'bash $(find $HOME -name crio-cluster-cp.sh)'

# Setup command line completion
ssh -i $PEM $user@$1 'source <(kubectl completion bash)'
ssh -i $PEM $user@$1 'echo "source <(kubectl completion bash)" >> $HOME/.bashrc'

# Copy files back to local node, then up to worker node
scp -i $PEM $user@$1:~/cpalias.txt .
scp -i $PEM $user@$1:~/joincommand.txt .

scp -oStrictHostKeyChecking=no -i $PEM ./cpalias.txt $user@$2:~
scp -i $PEM ./joincommand.txt $user@$2:~


# Worker: Download tar ball and expand
ssh -i $PEM $user@$2 'wget https://cm.lf.training/LFS460/LFS460_V1.19-beta_SOLUTIONS.tar.xz --user=LFtraining --password=Penguin2014'

ssh -i $PEM $user@$2 'tar -xvf LFS460_V1.19-beta_SOLUTIONS.tar.xz'

ssh -i $PEM $user@$2 'bash $(find $HOME -name crio-cluster-worker.sh)'

ssh -i $PEM $user@$2 'cat cpalias.txt | sudo tee -a /etc/hosts'

ssh -i $PEM $user@$2 'sudo bash joincommand.txt'
