# Docker Swarm Learning Guide

## Table of Contents
1. [Getting Started](#getting-started)
2. [Core Concepts](#core-concepts)
3. [Basic Commands](#basic-commands)
4. [Services & Scaling](#services--scaling)
5. [Stacks & Compose](#stacks--compose)
6. [Practice Exercises](#practice-exercises)
7. [Learning Path](#learning-path)
8. [Quick Reference](#quick-reference)

---

## Getting Started

### Prerequisites
- Complete the setup: `./setup-linux.sh`
- Start VMs: `vagrant up --provider=libvirt`
- Connect to manager: `vagrant ssh manager`

### First Swarm Command

Verify Docker and Swarm on manager node:
```bash
vagrant ssh manager
docker node ls
```

Expected output shows manager node in "Ready" and "Leader" status.

### Cluster Architecture
```
Linux Host
    |
    ├── vagrant ssh manager ──> Manager Node
    |                            └── Swarm Manager (controls cluster)
    |
    ├── vagrant ssh worker-1 ─> Worker Node 1
    |                            └── Swarm Worker
    |
    └── vagrant ssh worker-2 ─> Worker Node 2
                                 └── Swarm Worker
```

### Joining Workers to Swarm

On manager, get join token:
```bash
docker swarm join-token worker
```

Copy the join command and run it on each worker node after SSH-ing in.

---

## Core Concepts

### What is Docker Swarm?
Docker Swarm is Docker's native orchestration tool for clustering and scheduling Docker containers. It turns a pool of Docker hosts into a single virtual host.

### Key Components

1. **Node**: A Docker instance participating in the swarm (manager or worker)
2. **Manager Node**: Manages the swarm state, dispatches tasks, handles orchestration
3. **Worker Node**: Executes tasks assigned by managers
4. **Service**: Definition of the tasks to execute on workers (like a container template)
5. **Task**: A running container that is part of a service
6. **Overlay Network**: Multi-host network that enables communication between nodes
7. **Routing Mesh**: Automatically routes incoming requests to the appropriate service replica
8. **Stack**: A group of interrelated services defined in a Docker Compose file

### Swarm Architecture
```
Manager Node(s)
    ├── Maintains cluster state
    ├── Schedules services
    └── Provides API endpoint

Worker Node(s)
    ├── Receive tasks from managers
    ├── Run containers (tasks)
    └── Report status back to managers
```

---

## Basic Commands

### Node Management

```bash
# Initialize swarm (done automatically)
docker swarm init --advertise-addr <MANAGER_IP>

# Get join token for workers
docker swarm join-token worker

# Get join token for managers (adding more managers)
docker swarm join-token manager

# List nodes in swarm
docker node ls

# Inspect a node
docker node inspect manager

# Update node availability
docker node update --availability drain manager   # Drain (no new tasks)
docker node update --availability active manager  # Active (normal)
docker node update --availability pause manager   # Pause (no new tasks, existing stay)

# Remove a node from swarm
docker node rm worker-1

# Promote worker to manager
docker node promote worker-1

# Demote manager to worker
docker node demote manager
```

### Service Management

```bash
# Create a service
docker service create --name nginx -p 80:80 nginx:alpine

# Create service with replicas
docker service create --name nginx --replicas 3 -p 80:80 nginx:alpine

# List services
docker service ls

# Inspect a service
docker service inspect nginx

# View service tasks (which nodes run which containers)
docker service ps nginx

# Scale a service
docker service scale nginx=5

# Update a service
docker service update --image nginx:latest nginx
docker service update --replicas 3 nginx

# Remove a service
docker service rm nginx
```

### Networking

```bash
# List networks
docker network ls

# Create overlay network
docker network create --driver overlay my-overlay

# Create encrypted overlay network
docker network create --driver overlay --opt encrypted my-secure-overlay

# Inspect network
docker network inspect my-overlay

# Remove network
docker network rm my-overlay
```

---

## Services & Scaling

### Creating a Replicated Service

```bash
# Create a service with 3 replicas
docker service create \
  --name web \
  --replicas 3 \
  --publish published=80,target=80 \
  nginx:alpine

# Check where tasks are running
docker service ps web
```

### Rolling Updates

```bash
# Update service image (rolling update)
docker service update \
  --image nginx:1.25 \
  --update-parallelism 1 \
  --update-delay 10s \
  web

# Roll back to previous version
docker service rollback web
```

### Service Discovery

```bash
# Services can reach each other by service name
# Create a network
docker network create --driver overlay app-net

# Create services on that network
docker service create --name db --network app-net postgres:alpine
docker service create --name api --network app-net myapi:latest

# api service can reach db service via hostname "db"
```

---

## Stacks & Compose

### What is a Stack?
A stack is a group of services that are deployed together using a Docker Compose file.

### Example docker-stack.yml

```yaml
version: "3.8"

services:
  web:
    image: nginx:alpine
    ports:
      - "80:80"
    deploy:
      mode: replicated
      replicas: 3
      update_config:
        parallelism: 1
        delay: 10s
      restart_policy:
        condition: on-failure
    networks:
      - webnet

  visualizer:
    image: dockersamples/visualizer:stable
    ports:
      - "8080:8080"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
    deploy:
      placement:
        constraints: [node.role == manager]
    networks:
      - webnet

networks:
  webnet:
    driver: overlay
```

### Deploy Stack

```bash
# Deploy a stack
docker stack deploy -c docker-stack.yml myapp

# List stacks
docker stack ls

# List services in a stack
docker stack services myapp

# List tasks in a stack
docker stack ps myapp

# Remove a stack
docker stack rm myapp
```

---

## Practice Exercises

### Beginner Level

**Exercise 1: Initialize Swarm**
```bash
vagrant ssh manager
docker swarm init --advertise-addr $(hostname -I | awk '{print $1}')
docker node ls
```

**Exercise 2: Add Worker Nodes**
```bash
# On manager, get join command
docker swarm join-token worker

# SSH to each worker and run the join command
vagrant ssh worker-1
# Paste the join command here
```

**Exercise 3: Deploy First Service**
```bash
docker service create --name hello -p 80:80 nginx:alpine
docker service ls
curl localhost
```

**Exercise 4: Scale Service**
```bash
docker service scale hello=3
docker service ps hello
```

### Intermediate Level

**Exercise 5: Create Overlay Network**
```bash
docker network create --driver overlay my-net
docker service create --name web --network my-net -p 80:80 nginx:alpine
docker service create --name ping --network my-net alpine ping web
docker service logs ping
```

**Exercise 6: Deploy with Constraints**
```bash
docker service create \
  --name manager-only \
  --constraint "node.role==manager" \
  nginx:alpine
```

**Exercise 7: Rolling Update**
```bash
docker service create --name app --replicas 5 nginx:1.24
docker service update --image nginx:1.25 --update-parallelism 2 --update-delay 5s app
```

**Exercise 8: Service with Environment Variables**
```bash
docker service create \
  --name db \
  --env POSTGRES_PASSWORD=secret \
  --env POSTGRES_DB=mydb \
  postgres:alpine
```

### Advanced Level

**Exercise 9: Deploy a Stack**
Create `myapp-stack.yml` and deploy:
```bash
docker stack deploy -c myapp-stack.yml myapp
docker stack services myapp
```

**Exercise 10: Multi-tier Application**
Create a stack with:
- Web frontend (nginx)
- API backend (node/api)
- Database (postgres)
- Cache (redis)

**Exercise 11: Service Discovery**
```bash
# Create overlay network
docker network create --driver overlay app-net

# Deploy services
docker service create --name backend --network app-net backend:latest
docker service create --name frontend --network app-net frontend:latest

# Test: frontend can reach backend via hostname "backend"
```

**Exercise 12: Drain Node and Reschedule**
```bash
# Drain a node
docker node update --availability drain worker-1

# Watch tasks reschedule
docker service ps <service-name>

# Restore node
docker node update --availability active worker-1
```

---

## Learning Path

### Week 1: Swarm Basics
- [ ] Understand Swarm architecture
- [ ] Set up the learning environment
- [ ] Initialize a swarm
- [ ] Add worker nodes
- [ ] List and inspect nodes
- [ ] Remove and add nodes

### Week 2: Services
- [ ] Create simple services
- [ ] Scale services up and down
- [ ] Understand routing mesh
- [ ] Inspect service tasks
- [ ] Remove services
- [ ] Work with service logs

### Week 3: Networking & Discovery
- [ ] Create overlay networks
- [ ] Attach services to networks
- [ ] Test service discovery
- [ ] Understand routing mesh
- [ ] Use encrypted networks
- [ ] Expose ports correctly

### Week 4: Stacks & Production
- [ ] Write Docker Compose files for Swarm
- [ ] Deploy stacks
- [ ] Perform rolling updates
- [ ] Use constraints and placement
- [ ] Handle node failures
- [ ] Implement rollback strategies

---

## Quick Reference

### Common Swarm Commands

| Command | Description |
|---------|-------------|
| `docker swarm init` | Initialize a swarm |
| `docker swarm join` | Join a swarm as worker |
| `docker swarm join-token` | Manage join tokens |
| `docker node ls` | List nodes |
| `docker node inspect` | Inspect a node |
| `docker node update` | Update node settings |
| `docker node rm` | Remove a node |
| `docker service create` | Create a service |
| `docker service ls` | List services |
| `docker service ps` | List service tasks |
| `docker service scale` | Scale service |
| `docker service update` | Update service |
| `docker service rm` | Remove service |
| `docker stack deploy` | Deploy a stack |
| `docker stack ls` | List stacks |
| `docker stack rm` | Remove a stack |

### Service Create Options

| Option | Description |
|--------|-------------|
| `--name` | Service name |
| `--replicas` | Number of replicas |
| `--publish` | Publish port (routing mesh) |
| `--network` | Attach to network |
| `--env` | Environment variable |
| `--mount` | Mount volume |
| `--constraint` | Placement constraint |
| `--update-parallelism` | Parallel update count |
| `--update-delay` | Delay between updates |

### Node Availability States

| State | Description |
|-------|-------------|
| `active` | Normal state, receives tasks |
| `pause` | No new tasks, existing keep running |
| `drain` | No new tasks, existing moved elsewhere |

### Stack Deploy Options

| Option | Description |
|--------|-------------|
| `-c` | Compose file path |
| `--prune` | Remove services not in compose file |
| `--resolve-image` | Query registry for newer images |

---

## Resources

- **Official Docker Swarm Documentation**: https://docs.docker.com/engine/swarm/
- **Docker Swarm Tutorial**: https://docs.docker.com/engine/swarm/swarm-tutorial/
- **Docker Compose File Reference**: https://docs.docker.com/compose/compose-file/
- **Swarm Mode Overview**: https://docs.docker.com/engine/swarm/key-concepts/
- **Docker Hub**: https://hub.docker.com/
- **Swarm Visualizer**: https://github.com/dockersamples/docker-swarm-visualizer

---

**Happy Swarming!**
