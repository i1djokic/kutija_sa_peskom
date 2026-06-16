#!/bin/bash
# Script to install dependencies for Docker Swarm Learning Environment on Linux
# Uses libvirt/KVM as the hypervisor

set -e

echo "=========================================="
echo "Docker Swarm Learning - Linux Setup"
echo "Installing required dependencies..."
echo "=========================================="

if command -v apt &> /dev/null; then
    PKG_MANAGER="apt"
    INSTALL_CMD="apt install -y"
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
    INSTALL_CMD="dnf install -y"
else
    echo "Error: Unsupported package manager (only apt and dnf are supported)"
    exit 1
fi

echo "Detected package manager: $PKG_MANAGER"

GUI_PACKAGES=""
read -p "Install virt-manager (libvirt GUI)? [Y/n] " -n 1 -r REPLY
echo
if [[ "$REPLY" =~ ^[Yy]$ ]] || [[ -z "$REPLY" ]]; then
    GUI_PACKAGES="virt-manager"
fi

echo ""
echo "Installing libvirt and related packages..."
if [ "$PKG_MANAGER" = "apt" ]; then
    $INSTALL_CMD \
        libvirt-daemon-system \
        libvirt-clients \
        $GUI_PACKAGES \
        qemu-kvm \
        qemu-utils \
        bridge-utils \
        dnsmasq-base \
        ebtables \
        vagrant \
        vagrant-libvirt
elif [ "$PKG_MANAGER" = "dnf" ]; then
    $INSTALL_CMD \
        libvirt-daemon-kvm \
        libvirt-client \
        $GUI_PACKAGES \
        qemu-kvm \
        qemu-img \
        bridge-utils \
        dnsmasq \
        ebtables \
        vagrant \
        vagrant-libvirt
fi

echo ""
echo "Starting libvirtd service..."
sudo systemctl enable libvirtd
sudo systemctl start libvirtd

echo ""
echo "Adding user to libvirt group..."
sudo usermod -aG libvirt "$USER"
sudo usermod -aG kvm "$USER"

echo ""
echo "=========================================="
echo "Verifying installations..."
echo "=========================================="

echo -n "libvirtd: "
if systemctl is-active libvirtd &> /dev/null; then
    echo "Running"
else
    echo "Not running"
fi

echo -n "Vagrant: "
if command -v vagrant &> /dev/null; then
    vagrant --version
else
    echo "Not found"
fi

echo -n "vagrant-libvirt plugin: "
vagrant plugin list | grep libvirt || echo "Not found"

echo ""
echo "=========================================="
echo "Installation complete!"
echo "=========================================="
echo ""
echo "IMPORTANT: Log out and back in for group changes to take effect,"
echo "or run: newgrp libvirt"
echo ""
echo "Next steps:"
echo "1. Read the documentation: cat README.md"
echo "2. Start the Swarm cluster (1 manager + 2 workers): vagrant up --provider=libvirt"
echo "3. Connect to manager: vagrant ssh manager"
echo "4. Verify Swarm: docker node ls"
echo "5. Follow the learning guide: cat DOCKER_SWARM_LEARNING_GUIDE.md"
echo ""
