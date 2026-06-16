# Docker Learning Environment

## What is this?

A hands-on learning environment for Docker and Docker Compose. Docker runs inside a Vagrant-managed VM, keeping your Linux host clean.

Uses:
- **libvirt/KVM** - Open-source virtualizer
- **Vagrant** - VM management
- **Debian Bookworm** - Lightweight Linux distro
- **Docker** - Inside the VM (not on host)

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

## Starting the VM

```bash
# Start the VM (Docker will be installed automatically)
vagrant up --provider=libvirt

# Connect via SSH
vagrant ssh

# Inside VM: verify Docker installation
docker --version
docker compose version

# Stop the VM
vagrant halt

# Delete the VM (warning: irreversible)
vagrant destroy -f
```

## Learning Path

1. Learn Docker basics (containers, images, Dockerfile)
2. Run and manage containers
3. Create Dockerfiles
4. Use Docker Compose for multi-container apps
5. Practice with real-world examples

See [DOCKER_LEARNING_GUIDE.md](./DOCKER_LEARNING_GUIDE.md) for detailed instructions.

## Project Structure

```
docker-learning/
├── README.md                    # This file
├── setup-linux.sh               # Dependency installer
├── Vagrantfile                  # VM configuration
├── provision.sh                 # VM provisioning (installs Docker)
└── DOCKER_LEARNING_GUIDE.md    # Learning materials
```

## Docker Inside VM - Quick Examples

After connecting via `vagrant ssh`:

```bash
# Run your first container
docker run hello-world

# Run nginx web server
docker run -d -p 80:80 nginx

# List running containers
docker ps

# Create a simple Docker Compose app
mkdir ~/myapp && cd ~/myapp
cat > docker-compose.yml << 'EOF'
services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
EOF

docker compose up -d
```

## Port Forwarding

Access services running in Docker from your Linux browser:

```bash
# In Vagrantfile, ports are forwarded from VM to host
# Example: Docker container port 80 -> VM port 8080 -> Host port 8080
```

## Resources

- **libvirt**: https://libvirt.org/
- **Vagrant**: https://www.vagrantup.com/
- **Docker Documentation**: https://docs.docker.com/
- **Docker Compose Documentation**: https://docs.docker.com/compose/
- **Docker Hub**: https://hub.docker.com/
