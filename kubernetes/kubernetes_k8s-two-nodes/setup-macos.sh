#!/bin/bash
# Script to install dependencies for Kubernetes cluster setup with UTM + Vagrant on macOS
# For Apple Silicon (M1/M2/M3/M4) Macs

set -e  # Exit on error

echo "=========================================="
echo "Kubernetes on Apple Silicon Mac - Setup"
echo "Installing required dependencies..."
echo "=========================================="

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "Error: This script is for macOS only"
    exit 1
fi

# Check if running on Apple Silicon
ARCH=$(uname -m)
if [[ "$ARCH" != "arm64" ]]; then
    echo "Warning: This setup is optimized for Apple Silicon (ARM64)."
    echo "You're running on: $ARCH"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Install Homebrew if not present
if ! command -v brew &> /dev/null; then
    echo ""
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo ""
    echo "Homebrew already installed. Updating..."
    brew update
fi

# Install UTM (free, open-source virtualization for macOS)
echo ""
echo "Installing UTM..."
brew install --cask utm

# Install Vagrant
echo ""
echo "Installing Vagrant..."
brew install vagrant

# Install vagrant_utm plugin
echo ""
echo "Installing vagrant_utm plugin..."
vagrant plugin install vagrant_utm

# Verify installations
echo ""
echo "=========================================="
echo "Verifying installations..."
echo "=========================================="

echo -n "UTM: "
if command -v utmctl &> /dev/null; then
    echo "Installed ($(utmctl --version 2>&1 | head -1))"
else
    echo "Warning: UTM command line tools not found in PATH"
fi

echo -n "Vagrant: "
if command -v vagrant &> /dev/null; then
    vagrant --version
else
    echo "Not found"
fi

echo -n "vagrant_utm plugin: "
vagrant plugin list | grep utm || echo "Not found"

echo ""
echo "=========================================="
echo "Installation complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Read the documentation: cat README.md"
echo "2. Start the cluster: vagrant up --provider=utm"
echo "3. Check cluster status: vagrant ssh master -c 'sudo kubectl get nodes'"
echo ""
echo "Note: First VM boot may take 10-15 minutes to download the base image."
echo "See README.md for detailed instructions and troubleshooting."
