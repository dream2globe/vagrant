#!/usr/bin/env bash

# k8s init
sudo kubeadm init --apiserver-advertise-address 192.168.56.21 --pod-network-cidr=20.96.0.0/12
sudo kubeadm token create --print-join-command > /vagrant/k8s_join.sh

# for regular user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# calico
sudo curl https://docs.projectcalico.org/manifests/calico.yaml -O
kubectl apply -f calico.yaml

# auto-completion
sudo apt-get install bash-completion -y
echo 'source <(kubectl completion bash)' >>~/.bashrc
echo 'alias k=kubectl' >>~/.bashrc
echo 'complete -F __start_kubectl k' >>~/.bashrc
source ~/.bashrc