#!/bin/bash
set -e

echo "=== k3s Single-Node Setup ==="

systemctl stop firewalld
systemctl disable firewalld

swapoff -a
sed -i '/ swap /s/^/#/' /etc/fstab

setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Ensure SSH stays accessible — kube-proxy may add restrictive nftables rules
iptables -I INPUT -p tcp --dport 22 -j ACCEPT
iptables -I INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Retry helper
retry() {
  local n=5 delay=2
  for ((i = 0; i < n; i++)); do
    "$@" && return 0
    sleep $delay
    delay=$((delay * 2))
  done
  return 1
}

retry curl -sfL https://get.k3s.io | sh -

KUBECTL_VERSION=$(curl -sL https://dl.k8s.io/release/stable.txt)
curl -sLO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/kubectl
ln -sf /usr/local/bin/kubectl /usr/bin/kubectl

echo ""
echo "=== k3s Installation Complete ==="
echo ""
echo "To use kubectl from your host:"
echo "  vagrant ssh -c \"sudo cat /etc/rancher/k3s/k3s.yaml\" > k3s.yaml"
echo "  sed -i '' 's/127.0.0.1/192.168.64.10/' k3s.yaml"
echo "  export KUBECONFIG=\$(pwd)/k3s.yaml"
echo "  kubectl get nodes"
