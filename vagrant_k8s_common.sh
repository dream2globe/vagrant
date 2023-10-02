#!/usr/bin/env bash


# Network setting
sudo modprobe overlay
sudo modprobe br_netfilter

sudo cat << EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system


# OS
sudo ufw disable  # firewall disable 
sudo swapoff -a && sudo sed -i '/ swap / s/^/#/' /etc/fstab  # swap off


# Host
sudo cat << EOF | sudo tee /etc/hosts
192.168.56.20  kmaster
192.168.56.21  kworker1
192.168.56.22  kworker2
192.168.56.23  kworker3
EOF


# Install docker
## Add sudo user
sudo groupadd docker
sudo usermod -aG docker $USER

## Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg -y
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

## Add the repository to Apt sources:
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

## Install the Docker packages:
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

## Docker Runtime
# curl -fsSLo ./cri-dockerd_0.3.4.3-0.ubuntu-jammy_amd64.deb https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.4/cri-dockerd_0.3.4.3-0.ubuntu-jammy_amd64.deb 
# sudo dpkg -i cri-dockerd_0.3.4.3-0.ubuntu-jammy_amd64.deb 
## containerd로 변경
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/            SystemdCgroup = false/            SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl daemon-reload
sudo systemctl restart containerd


# Install K8S
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# ceph dependencies
sudo apt-get install -y lvm2