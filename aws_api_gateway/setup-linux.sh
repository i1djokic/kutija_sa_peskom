#!/bin/bash
# Script to install dependencies for AWS API Gateway & Lambda project on Linux

set -e

echo "=========================================="
echo "AWS API Gateway & Lambda - Linux Setup"
echo "Installing required dependencies..."
echo "=========================================="

if command -v apt &> /dev/null; then
    PKG_MANAGER="apt"
    INSTALL_CMD="apt install -y"
    PYTHON_PKG="python3 python3-pip"
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
    INSTALL_CMD="dnf install -y"
    PYTHON_PKG="python3 python3-pip"
else
    echo "Error: Unsupported package manager (only apt and dnf are supported)"
    exit 1
fi

echo "Detected package manager: $PKG_MANAGER"

echo ""
echo "Installing Python3 and pip..."
$INSTALL_CMD $PYTHON_PKG

echo ""
echo "Installing AWS CLI..."
pip3 install awscli

echo ""
echo "Installing AWS SAM CLI..."
pip3 install aws-sam-cli

echo ""
echo "Installing floci (local AWS emulator)..."
pip3 install floci

echo ""
echo "=========================================="
echo "Verifying installations..."
echo "=========================================="

echo -n "AWS CLI: "
if command -v aws &> /dev/null; then
    aws --version
else
    echo "Not found"
fi

echo -n "Python3: "
if command -v python3 &> /dev/null; then
    python3 --version
else
    echo "Not found"
fi

echo -n "pip3: "
if command -v pip3 &> /dev/null; then
    pip3 --version
else
    echo "Not found"
fi

echo -n "SAM CLI: "
if command -v sam &> /dev/null; then
    sam --version
else
    echo "Not found"
fi

echo -n "floci: "
if command -v floci &> /dev/null; then
    floci --version 2>&1 || echo "Installed"
else
    echo "Not found"
fi

echo ""
echo "=========================================="
echo "Installation complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Configure AWS credentials: aws configure"
echo "2. For local testing, start floci: docker run -p 4566:4566 floci/floci:latest"
echo "3. Run local demo: ./floci-demo.sh"
echo "4. Deploy to AWS: ./deploy.sh"
echo ""
