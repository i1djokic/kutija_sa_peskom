# Docker Swarm Learning Environment

## What is this?

A hands-on learning environment for Docker Swarm orchestration. Docker Swarm runs inside Vagrant-managed VMs, keeping your Linux host clean.

Uses:
- **libvirt/KVM** - Open-source virtualizer
- **Vagrant** - VM management
- **Debian Bookworm** - Lightweight Linux distro
- **Docker Swarm** - Inside the VMs (not on host)

**Total cost: $0** - Everything is free and open-source!

## Prerequisites

- Linux with KVM-capable CPU (most modern CPUs)
- libvirt and Vagrant installed
- Internet connection

## Quick Setup

### Option 1: Automated Setup (Recommended)

```bash
chmod +x setup-linux.sh
./setup-linux.sh
```

### Option 2: Manual Setup

```bash
# Install libvirt/KVM (Debian/Ubuntu)
sudo apt install -y libvirt-daemon-system libvirt-clients qemu-kvm virt-manager vagrant vagrant-libvirt

# Start libvirtd
sudo systemctl enable --now libvirtd

# Add user to groups
sudo usermod -aG libvirt,kvm $USER
newgrp libvirt
```

## Starting the VMs

```bash
# Start the Swarm cluster (1 manager + 2 workers by default)
vagrant up --provider=libvirt

# Or customize number of workers:
WORKER_COUNT=3 vagrant up --provider=libvirt

# Connect to manager node
vagrant ssh manager

# Inside manager: verify Swarm is initialized
docker node ls

# Connect to a worker node
vagrant ssh worker-1

# Stop all VMs
vagrant halt

# Delete all VMs (warning: irreversible)
vagrant destroy -f
```

## Learning Path

1. Learn Docker Swarm basics (nodes, services, overlay network)
2. Initialize and manage Swarm clusters
3. Deploy and scale services
4. Use routing mesh and load balancing
5. Manage stacks with Docker Compose

See [DOCKER_SWARM_LEARNING_GUIDE.md](./DOCKER_SWARM_LEARNING_GUIDE.md) for detailed instructions.

## Project Structure

```
docker_swarm/
├── README.md                        # This file
├── setup-linux.sh                   # Dependency installer for Linux
├── Vagrantfile                      # Multi-VM configuration
├── provision.sh                     # VM provisioning (installs Docker)
└── DOCKER_SWARM_LEARNING_GUIDE.md  # Learning materials
```

## Cluster Architecture

```
Linux Host
    |
    ├── vagrant ssh manager ──> Manager Node (manager)
    |                            └── Docker Swarm Manager
    |
    ├── vagrant ssh worker-1 ──> Worker Node 1 (worker-1)
    |                            └── Docker Swarm Worker
    |
    └── vagrant ssh worker-2 ──> Worker Node 2 (worker-2)
                                 └── Docker Swarm Worker
```

## Quick Swarm Examples

After connecting to manager via `vagrant ssh manager`:

```bash
# Initialize Swarm (done automatically by provisioning)
docker node ls

# Deploy a service
docker service create --name nginx --replicas 3 -p 80:80 nginx:alpine

# List services
docker service ls

# Scale service
docker service scale nginx=5

# View service details
docker service ps nginx

# Remove service
docker service rm nginx
```

## Port Forwarding

Access services running in Swarm from your Linux browser:

```bash
# Services deployed on port 80 are accessible via:
# http://localhost:8080 (forwarded from manager VM)
```

## Resources

- **libvirt**: https://libvirt.org/
- **Vagrant**: https://www.vagrantup.com/
- **Docker Documentation**: https://docs.docker.com/
- **Docker Swarm Documentation**: https://docs.docker.com/engine/swarm/
- **Docker Hub**: https://hub.docker.com/
