#!/bin/bash

# =============================================================================
# Kubernetes Cluster Initialization Script with Vagrant (UTM Provider for ARM64)
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script version
VERSION="1.1.0"

# Print colored output
print_status() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if Vagrant is installed
    if ! command -v vagrant &> /dev/null; then
        print_error "Vagrant is not installed. Please install Vagrant first."
        print_error "Download from: https://www.vagrantup.com/downloads"
        exit 1
    fi
    
    # Check if we're on ARM64 system (Apple Silicon)
    if [[ "$(uname -m)" == "arm64" ]]; then
        print_status "Detected ARM64 (Apple Silicon) system"
        print_status "Using UTM provider (free, open-source)"
        
        # Check if UTM is installed
        if ! command -v utmctl &> /dev/null && ! [ -d "/Applications/UTM.app" ]; then
            print_error "UTM is not installed. Please install UTM first."
            print_error "Download from: https://mac.getutm.app/"
            exit 1
        fi
        
        # Check if vagrant_utm plugin is installed
        if ! vagrant plugin list | grep -q "vagrant_utm"; then
            print_error "vagrant_utm plugin is not installed."
            print_error "Run: vagrant plugin install vagrant_utm"
            exit 1
        fi
    else
        # Intel Mac - check VirtualBox
        if ! command -v VBoxManage &> /dev/null; then
            print_error "VirtualBox is not installed. Please install VirtualBox first."
            print_error "Download from: https://www.virtualbox.org/wiki/Downloads"
            exit 1
        fi
    fi
    
    # Check Vagrant version
    vagrant_version=$(vagrant --version 2>/dev/null | head -n1 | cut -d' ' -f2)
    if [[ -z "$vagrant_version" ]]; then
        print_warning "Could not determine Vagrant version"
    else
        print_status "Vagrant version: $vagrant_version"
    fi
    
    print_success "All prerequisites satisfied"
}

# Show script usage
show_usage() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  up          Start and provision the Kubernetes cluster"
    echo "  down        Shut down and destroy the cluster"
    echo "  status      Show current cluster status"
    echo "  ssh master  SSH into the master node"
    echo "  ssh worker  SSH into the worker node"
    echo "  provision   Re-run provisioning scripts"
    echo "  help        Show this help message"
    echo "  version     Show script version"
    echo ""
    echo "Examples:"
    echo "  $0 up                    # Start the cluster"
    echo "  $0 down                  # Destroy the cluster"
    echo "  $0 ssh master            # Connect to master node"
    echo "  $0 status                # Check cluster status"
}

# Start the cluster
start_cluster() {
    print_status "Starting Kubernetes cluster..."
    
    # Check if cluster is already running
    if vagrant status | grep -q "master.*running"; then
        print_warning "Cluster is already running"
        return 0
    fi
    
    # Start with appropriate provider
    if [[ "$(uname -m)" == "arm64" ]]; then
        print_status "Starting with UTM provider (Apple Silicon)..."
        vagrant up --provider=utm
    else
        print_status "Starting with VirtualBox provider..."
        vagrant up
    fi
    
    print_success "Kubernetes cluster started successfully"
    print_status "To access the master node, run: $0 ssh master"
    print_status "To access the worker node, run: $0 ssh worker"
}

# Stop the cluster
stop_cluster() {
    print_status "Stopping Kubernetes cluster..."
    
    # Check if cluster is running
    if ! vagrant status | grep -q "master.*running"; then
        print_warning "Cluster is not running"
        return 0
    fi
    
    # Destroy the cluster
    if [[ "$(uname -m)" == "arm64" ]]; then
        print_status "Destroying with UTM provider..."
        vagrant destroy -f --provider=utm
    else
        print_status "Destroying with VirtualBox provider..."
        vagrant destroy -f
    fi
    
    print_success "Kubernetes cluster destroyed successfully"
}

# Show cluster status
show_status() {
    print_status "Checking cluster status..."
    vagrant status
}

# SSH into a node
ssh_node() {
    local node="$1"
    
    if [[ "$node" != "master" && "$node" != "worker" ]]; then
        print_error "Invalid node. Use 'master' or 'worker'"
        exit 1
    fi
    
    print_status "Connecting to $node node..."
    vagrant ssh "$node"
}

# Re-provision the cluster
reprovision() {
    print_status "Re-running provisioning scripts..."
    
    # Check if cluster is running
    if ! vagrant status | grep -q "master.*running"; then
        print_warning "Cluster is not running. Starting it first..."
        if [[ "$(uname -m)" == "arm64" ]]; then
            vagrant up --provider=utm
        else
            vagrant up
        fi
    fi
    
    # Reprovision
    vagrant provision
    
    print_success "Provisioning completed successfully"
}

# Main function
main() {
    # Parse command line arguments
    case "${1:-}" in
        up)
            check_prerequisites
            start_cluster
            ;;
        down)
            stop_cluster
            ;;
        status)
            show_status
            ;;
        ssh)
            if [[ $# -lt 2 ]]; then
                print_error "Missing node argument for ssh command"
                show_usage
                exit 1
            fi
            ssh_node "$2"
            ;;
        provision)
            reprovision
            ;;
        help|-h|--help)
            show_usage
            ;;
        version|-v|--version)
            echo "Kubernetes Cluster Init Script v$VERSION"
            ;;
        *)
            if [[ $# -gt 0 ]]; then
                print_error "Unknown command: $1"
                show_usage
                exit 1
            else
                check_prerequisites
                start_cluster
            fi
            ;;
    esac
}

# Run main function with all arguments
main "$@"