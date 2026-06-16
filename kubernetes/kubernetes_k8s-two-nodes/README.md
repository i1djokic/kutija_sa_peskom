# Kubernetes on Apple Silicon (M1/M2/M3/M4) using UTM + Vagrant

## What is this?

This project provides a **free and open-source** way to run a local Kubernetes cluster on Apple Silicon Macs (M1/M2/M3/M4) using:

- **UTM** - Free, open-source virtualizer for macOS (uses QEMU)
- **Vagrant** - Tool for building and managing VM environments
- **vagrant_utm** - Plugin to use Vagrant with UTM
- **CentOS Stream 9** - Linux distribution optimized for ARM64

**Total cost: $0** - Everything is free and open-source!

## Why this approach?

| Solution | Cost | Open-Source | Apple Silicon Support |
|----------|------|-------------|----------------------|
| **UTM + Vagrant (this project)** | ✅ Free | ✅ Yes | ✅ Native ARM64 |
| VirtualBox + Vagrant | ✅ Free | ✅ Yes | ❌ No (no ARM virtualization) |
| Parallels + Vagrant | ❌ Paid | ❌ No | ✅ Yes |
| Docker Desktop + Kind | ✅ Free | ✅ Yes | ✅ Yes (but no real VMs) |

## Prerequisites

Before starting, you need:

1. **Apple Silicon Mac** (M1/M2/M3/M4)
2. **macOS** (Ventura, Sonoma, or later)
3. **Internet connection** (for downloading dependencies)

## Quick Setup

### Option 1: Automated Setup (Recommended)

Run the setup script that installs all dependencies:

```bash
cd /path/to/this/project
chmod +x setup-macos.sh
./setup-macos.sh
```

This script will install:
- Homebrew (if not present)
- UTM
- Vagrant
- vagrant_utm plugin

### Option 2: Manual Setup

If you prefer to install manually:

```bash
# Install Homebrew (if needed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install UTM
brew install --cask utm

# Install Vagrant
brew install vagrant

# Install vagrant_utm plugin
vagrant plugin install vagrant_utm
```

## Starting the Kubernetes Cluster

After installing dependencies:

```bash
# Start the cluster (first run downloads base image, ~5-10 minutes)
vagrant up --provider=utm

# Check VM status
vagrant status

# SSH into master node
vagrant ssh master

# Check Kubernetes cluster
kubectl get nodes
kubectl get pods -A
```

## What Gets Created

The cluster consists of:

- **1 Master Node** (`k8s-master`)
  - 4GB RAM, 2 CPU cores
  - Runs: API server, etcd, scheduler, controller-manager
  - IP: `192.168.56.10`

- **1 Worker Node** (`k8s-worker`)
  - 2GB RAM, 1 CPU core
  - Runs: kubelet, kube-proxy, Calico agent
  - IP: `192.168.56.11`

- **Networking**: Calico v3.27.0
- **Kubernetes version**: v1.30.14

## Using the Cluster

### From Master Node

```bash
# SSH into master
vagrant ssh master

# Use kubectl (auto-configured with admin.conf)
sudo kubectl get nodes
sudo kubectl get pods -A

# Deploy a test application
sudo kubectl run nginx --image=nginx
sudo kubectl get pods -o wide
```

### From Your Mac

To use kubectl from your Mac (optional):

```bash
# Copy kubeconfig from master
vagrant ssh master -c "sudo cat /etc/kubernetes/admin.conf" > ~/.kube/config

# Install kubectl on your Mac (if not present)
brew install kubectl

# Now you can use kubectl from your Mac
kubectl get nodes
kubectl get pods -A
```

## Vagrant Commands

```bash
# Start VMs
vagrant up --provider=utm

# Stop VMs
vagrant halt

# Restart VMs
vagrant reload

# Destroy VMs (warning: deletes everything)
vagrant destroy -f

# Re-provision (re-run setup scripts)
vagrant provision

# SSH into VMs
vagrant ssh master
vagrant ssh worker

# Check status
vagrant status
```

## Troubleshooting

### Issue: VMs won't start

```bash
# Check UTM is installed
open -a UTM

# Check plugin is installed
vagrant plugin list | grep utm

# Check macOS permissions
# Go to: System Settings → Privacy & Security → Automation
# Ensure Terminal has permission
```

### Issue: Worker can't join cluster

The most common issue is network configuration. UTM's DHCP assigns the same IP to all VMs.

**Solution**: The Vagrantfile configures static IPs (`192.168.56.10` for master, `192.168.56.11` for worker). If this doesn't work:

```bash
# On master VM
vagrant ssh master
sudo ip addr add 192.168.56.10/24 dev enp0s1

# On worker VM
vagrant ssh worker
sudo ip addr add 192.168.56.11/24 dev enp0s1
```

### Issue: Calico pods crash

If Calico (network plugin) pods are crashing:

```bash
# Check logs
vagrant ssh master
sudo kubectl logs -n kube-system -l k8s-app=calico-node

# Reinstall Calico with correct interface
curl -s https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml | \
  sed 's/value: "autodetect"/value: "interface=enp0s1"/g' | \
  sudo kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f -
```

### Issue: kubectl commands fail with "connection refused"

```bash
# Check if API server is running
vagrant ssh master
sudo kubectl --kubeconfig=/etc/kubernetes/admin.conf get pods -n kube-system | grep apiserver

# Check API server logs
sudo kubectl --kubeconfig=/etc/kubernetes/admin.conf logs -n kube-system kube-apiserver-k8s-master
```

## Project Structure

```
.
├── README.md                    # This file
├── SETUP_GUIDE.md              # Detailed setup guide
├── Vagrantfile                 # VM configuration
├── init-k8s-cluster.sh         # Cluster initialization script
├── install-k8s-deps.sh         # Install K8s dependencies on a node
├── provision.sh                # Unified node provisioning script
└── setup-macos.sh              # Automated dependency installer for macOS

## Resources

- **UTM**: https://mac.getutm.app/
- **UTM Documentation**: https://docs.getutm.app/
- **vagrant_utm plugin**: https://github.com/naveenrajm7/vagrant_utm
- **vagrant_utm docs**: https://naveenrajm7.github.io/vagrant_utm/
- **Kubernetes**: https://kubernetes.io/
- **Calico**: https://www.tigera.io/project-calico/

## License

This project is provided as-is, free to use and modify.

## Contributing

Found an issue? Want to improve something? Feel free to open an issue or submit a pull request!
