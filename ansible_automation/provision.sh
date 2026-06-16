#!/bin/bash
# Provisioning script for Vagrant VMs
# Installs Python and essential packages for Ansible management

set -euo pipefail

NODE_TYPE="${1:-}"

if [[ -z "$NODE_TYPE" ]]; then
    echo "Usage: $0 [target]"
    exit 1
fi

# Common setup for all nodes
echo "=== Common Setup ==="
apt-get update
apt-get install -y \
    curl \
    wget \
    vim \
    git \
    python3 \
    python3-pip \
    python3-apt \
    python3-setuptools

echo "=== Python Version ==="
python3 --version

if [[ "$NODE_TYPE" = "target" ]]; then
    echo "=== Target Node Ready ==="
fi
