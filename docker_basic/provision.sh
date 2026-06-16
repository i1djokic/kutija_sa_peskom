#!/bin/bash
# Provisioning script for Docker Learning Environment
# Installs Docker and Docker Compose inside the VM

set -e

echo "=========================================="
echo "Docker Learning - VM Provisioning"
echo "Installing Docker and Docker Compose..."
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
    git

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

# Verify installations
echo ""
echo "=========================================="
echo "Verifying installations..."
echo "=========================================="

echo -n "Docker: "
docker --version

echo -n "Docker Compose: "
docker compose version

echo -n "Docker service: "
systemctl is-active docker

echo ""
echo "=========================================="
echo "Provisioning complete!"
echo "=========================================="
echo ""
echo "Docker is ready! Run 'vagrant ssh' to start using Docker."
echo ""
