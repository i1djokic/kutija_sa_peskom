#!/bin/bash
# Provisioning script for Docker Swarm Learning Environment
# Installs Docker inside the VMs and sets up Swarm

set -e

NODE_TYPE="${1:-}"

if [[ -z "$NODE_TYPE" ]]; then
    echo "Usage: $0 [manager|worker]"
    exit 1
fi

echo "=========================================="
echo "Docker Swarm Learning - VM Provisioning"
echo "Installing Docker..."
echo "=========================================="

# Update package list
echo "Updating package list..."
apt update

# Install prerequisites
echo "Installing prerequisites..."
apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    vim \
    git \
    net-tools

# Add Docker's official GPG key
echo "Adding Docker GPG key..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo "Adding Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
echo "Installing Docker Engine..."
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
echo "Starting Docker service..."
systemctl start docker
systemctl enable docker

# Add vagrant user to docker group
echo "Adding vagrant user to docker group..."
usermod -aG docker vagrant

# Verify Docker installation
echo "Verifying Docker installation..."
docker --version
docker compose version

# Role-specific setup
if [[ "$NODE_TYPE" = "manager" ]]; then
    echo "=========================================="
    echo "Setting up Manager Node"
    echo "=========================================="

    # Wait for all workers to be ready (they need to join the swarm)
    # Get the manager's IP address
    MANAGER_IP=$(hostname -I | awk '{print $1}')

    # Initialize Swarm
    echo "Initializing Docker Swarm..."
    docker swarm init --advertise-addr $MANAGER_IP

    # Get the join token for workers
    echo "=========================================="
    echo "Swarm initialized! Worker join command:"
    echo "=========================================="
    docker swarm join-token worker

    echo ""
    echo "Manager node is ready!"
    echo "Run 'docker node ls' to see the cluster status"
fi

if [[ "$NODE_TYPE" = "worker" ]]; then
    echo "=========================================="
    echo "Setting up Worker Node"
    echo "=========================================="

    # Workers will need to wait for manager to be ready
    # In production, you'd get the join token from the manager
    echo "Worker node is ready!"
    echo "Join this worker to the swarm using the command from the manager:"
    echo "docker swarm join --token <TOKEN> <MANAGER_IP>:2377"
fi

echo ""
echo "=========================================="
echo "Provisioning complete!"
echo "=========================================="
echo ""
