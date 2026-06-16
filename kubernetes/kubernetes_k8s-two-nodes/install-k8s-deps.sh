#!/bin/bash
# Install all system dependencies for kubeadm init
# RHEL-based only (Rocky Linux, CentOS Stream, RHEL)
# Run as root on every node BEFORE kubeadm init

set -e

echo "=== Installing Kubernetes system dependencies ==="

# Enable EPEL
dnf install -y epel-release

# Update packages
dnf makecache

# Install base utilities & time sync
dnf install -y \
    curl \
    wget \
    git \
    chrony \
    containerd

# Time sync
systemctl enable chrony --now

# Disable swap (kubeadm requirement)
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# Disable firewalld + set SELinux permissive (interfere with K8s networking & pods)
systemctl stop firewalld 2>/dev/null || true
systemctl disable firewalld 2>/dev/null || true
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Kernel modules
modprobe overlay
modprobe br_netfilter

cat > /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF

# Sysctl
cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
EOF

sysctl --system

# Configure containerd with systemd cgroup driver
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

systemctl restart containerd
systemctl enable containerd

# Add Kubernetes RPM repository (multi-arch, works on arm64)
cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.36/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.36/rpm/repodata/repomd.xml.key
EOF

dnf makecache

# Install kubelet, kubeadm, kubectl
dnf install -y kubelet kubeadm kubectl

# Hold versions — prevent accidental updates
echo "exclude=kubelet kubeadm kubectl" >> /etc/dnf/dnf.conf

# Enable kubelet (it will stay in crashloop until kubeadm init/join)
systemctl enable kubelet

echo ""
echo "=== DONE ==="
echo "Run: kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=<YOUR_IP>"
