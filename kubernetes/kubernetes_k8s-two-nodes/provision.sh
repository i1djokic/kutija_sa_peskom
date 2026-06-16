#!/bin/bash
# Unified Kubernetes Node Provisioning Script
# Usage: ./provision.sh [master|worker]
# For RHEL-based systems (Rocky Linux, CentOS Stream, RHEL)

set -e

NODE_TYPE="${1:-}"

if [[ -z "$NODE_TYPE" ]]; then
    echo "Error: Please specify node type"
    echo "Usage: $0 [master|worker]"
    exit 1
fi

if [[ "$NODE_TYPE" != "master" && "$NODE_TYPE" != "worker" ]]; then
    echo "Error: Invalid node type '$NODE_TYPE'"
    echo "Usage: $0 [master|worker]"
    exit 1
fi

echo "=== Kubernetes $NODE_TYPE Node Provisioning Started (CentOS Stream 10) ==="

# Detect package manager
if command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
    PKG_CHECK="makecache"
    PKG_INSTALL="install -y"
else
    echo "Error: No supported package manager found (dnf required for this script)"
    exit 1
fi

# Enable EPEL for additional packages
$PKG_MANAGER $PKG_INSTALL epel-release

# Ensure system is updated
$PKG_MANAGER $PKG_CHECK

# Install core server utilities
$PKG_MANAGER $PKG_INSTALL \
    vim \
    curl \
    wget \
    git \
    net-tools \
    iproute \
    chrony

# Enable and start time sync
systemctl enable chronyd
systemctl start chronyd

systemctl disable firewalld
systemctl stop firewalld

# Ensure no GUI is installed
systemctl set-default multi-user.target

# Disable swap (Kubernetes requirement) — handle tabs and spaces
swapoff -a || true
sed -i '/[[:space:]]swap[[:space:]]/s/^/#/' /etc/fstab
sed -i '/\/dev\/.*swap/d' /etc/fstab  # also remove device-based swap entries

# Disable firewalld — blocks Kubernetes pod/service ports
systemctl stop firewalld 2>/dev/null || true
systemctl disable firewalld 2>/dev/null || true

# Set SELinux to permissive mode — required for Kubernetes
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Load required kernel modules
modprobe overlay
modprobe br_netfilter

# Make kernel modules persistent
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# Set networking rules
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
EOF

sysctl --system

# Install containerd
$PKG_MANAGER $PKG_INSTALL containerd

# Create containerd config
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml

# Enable systemd cgroups
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Restart containerd
systemctl restart containerd
systemctl enable containerd

# Add Kubernetes repository (RPM method, multi-arch, works on arm64)
cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.36/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.36/rpm/repodata/repomd.xml.key
EOF

$PKG_MANAGER $PKG_CHECK

# Install latest Kubernetes components for this minor version
$PKG_MANAGER $PKG_INSTALL kubelet kubeadm kubectl

# Hold versions — prevent accidental updates
echo "exclude=kubelet kubeadm kubectl" >> /etc/dnf/dnf.conf

# Configure kubelet (RHEL/CentOS path)
mkdir -p /etc/sysconfig
cat > /etc/sysconfig/kubelet <<EOF
KUBELET_EXTRA_ARGS="--cgroup-driver=systemd"
EOF

# Enable and start kubelet
systemctl enable kubelet
systemctl start kubelet

# Master-specific setup (no kubeadm init — user runs it separately)
if [[ "$NODE_TYPE" = "master" ]]; then
    echo "=== Kubernetes Master Node Provisioning Completed Successfully ==="
    echo "To complete the master setup, run the following ON THIS NODE:"
    echo ""
    echo "  1. Initialize the cluster:"
    echo "     kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=<NODE_IP>"
    echo ""
    echo "  2. Configure kubectl (root):"
    echo "     mkdir -p /root/.kube"
    echo "     cp -i /etc/kubernetes/admin.conf /root/.kube/config"
    echo ""
    echo "  3. Install a CNI plugin (Calico example):"
    echo "     kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml"
    echo ""
    echo "  4. (Optional) Allow pods on control-plane:"
    echo "     kubectl taint nodes --all node-role.kubernetes.io/control-plane-"
    echo ""
    echo "  5. Get join command for workers:"
    echo "     kubeadm token create --print-join-command"
fi

# Worker-specific info
if [[ "$NODE_TYPE" = "worker" ]]; then
    echo "=== Kubernetes Worker Node Provisioning Completed Successfully ==="
    echo "To join this node to the cluster, run the join command from the master:"
    echo ""
    echo "  1. On the master, run: kubeadm token create --print-join-command"
    echo "  2. Run the output of that command ON THIS NODE"
    echo ""
    echo "Example (replace token and hash):"
    echo "  kubeadm join <MASTER_IP>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>"
fi
