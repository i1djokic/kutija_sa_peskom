# Docker Learning Guide

## Table of Contents
1. [Getting Started](#getting-started)
2. [Core Concepts](#core-concepts)
3. [Basic Commands](#basic-commands)
4. [Docker Compose](#docker-compose)
5. [Practice Exercises](#practice-exercises)
6. [Learning Path](#learning-path)
7. [Quick Reference](#quick-reference)

---

## Getting Started

### Prerequisites
- Complete the setup: `./setup-linux.sh`
- Start VM: `vagrant up --provider=libvirt`
- Connect to VM: `vagrant ssh`

### First Docker Command

Verify Docker installation inside the VM:
```bash
docker --version
docker compose version
```

Run your first container:
```bash
docker run hello-world
```

Expected output: A "Hello from Docker!" message confirming Docker works.

### Basic Workflow
```
Linux Host
    |
    └── vagrant ssh ──> VM (docker-vm)
                            |
                            └── docker commands run here
```

---

## Core Concepts

### What is Docker?
Docker is a platform for developing, shipping, and running applications in containers - lightweight, standalone, executable packages that include everything needed to run an application.

### Key Components

1. **Image**: A read-only template with instructions for creating a container
2. **Container**: A runnable instance of an image
3. **Dockerfile**: A text file with instructions to build an image
4. **Docker Compose**: Tool for defining multi-container applications
5. **Registry**: Storage for Docker images (Docker Hub is the default public registry)
6. **Volume**: Persistent data storage for containers
7. **Network**: Communication between containers

### Architecture
```
Docker Client (CLI)
    |
    └── Docker Daemon (inside VM)
            |
            ├── Pulls images from Registry
            ├── Creates containers from images
            └── Manages containers, networks, volumes
```

---

## Basic Commands

### Image Management

```bash
# Search for images
docker search nginx

# Pull an image
docker pull nginx:alpine

# List images
docker images
docker image ls

# Remove an image
docker rmi nginx:alpine

# Remove unused images
docker image prune
```

### Container Management

```bash
# Run a container
docker run -d --name my-nginx -p 80:80 nginx:alpine

# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# Stop a container
docker stop my-nginx

# Start a stopped container
docker start my-nginx

# Restart a container
docker restart my-nginx

# Remove a container
docker rm my-nginx

# Remove running container forcefully
docker rm -f my-nginx

# View container logs
docker logs my-nginx

# Follow logs in real-time
docker logs -f my-nginx
```

### Executing Commands in Containers

```bash
# Run a command in a running container
docker exec my-nginx ls /usr/share/nginx/html

# Open a shell inside a container
docker exec -it my-nginx sh

# Run a one-off command
docker exec my-nginx cat /etc/os-release
```

### Inspecting Containers

```bash
# View container details
docker inspect my-nginx

# View container stats (CPU, memory, network)
docker stats my-nginx

# View container processes
docker top my-nginx
```

### Volume Management

```bash
# Create a volume
docker volume create my-data

# List volumes
docker volume ls

# Inspect a volume
docker volume inspect my-data

# Remove a volume
docker volume rm my-data

# Remove unused volumes
docker volume prune
```

### Network Management

```bash
# List networks
docker network ls

# Create a network
docker network create my-network

# Inspect a network
docker network inspect my-network

# Remove a network
docker network rm my-network

# Connect container to network
docker network connect my-network my-nginx
```

---

## Docker Compose

### What is Docker Compose?
A tool for defining and running multi-container Docker applications. Use a YAML file to configure your application's services.

### Basic docker-compose.yml Structure

```yaml
services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./html:/usr/share/nginx/html
    networks:
      - app-network

  db:
    image: postgres:alpine
    environment:
      POSTGRES_PASSWORD: example
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - app-network

networks:
  app-network:

volumes:
  db-data:
```

### Docker Compose Commands

```bash
# Start services
docker compose up

# Start in detached mode
docker compose up -d

# Stop services
docker compose down

# Stop and remove volumes
docker compose down -v

# View running services
docker compose ps

# View logs
docker compose logs

# Follow logs
docker compose logs -f

# Execute command in a service
docker compose exec web sh

# Scale a service
docker compose up -d --scale web=3
```

---

## Practice Exercises

### Beginner Level

**Exercise 1: Hello World**
```bash
docker run hello-world
```

**Exercise 2: Run Nginx**
```bash
docker run -d --name web -p 80:80 nginx:alpine
# Access in browser: http://localhost:8080 (port forwarded from VM)
docker ps
docker stop web
docker rm web
```

**Exercise 3: Interactive Container**
```bash
docker run -it --name test alpine sh
# Inside container: ls, pwd, exit
docker rm test
```

**Exercise 4: Create a Simple Dockerfile**
Create `Dockerfile`:
```dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
```
Build and run:
```bash
echo "Hello Docker!" > index.html
docker build -t my-nginx .
docker run -d -p 80:80 my-nginx
```

### Intermediate Level

**Exercise 5: Volume Mounting**
```bash
mkdir ~/html
echo "Hello from Volume" > ~/html/index.html
docker run -d -p 80:80 -v ~/html:/usr/share/nginx/html nginx:alpine
# Access http://localhost:8080 - should show "Hello from Volume"
```

**Exercise 6: Multi-Container with Docker Compose**
Create `docker-compose.yml`:
```yaml
services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
  redis:
    image: redis:alpine
```
Run:
```bash
docker compose up -d
docker compose ps
docker compose down
```

**Exercise 7: Environment Variables**
```bash
docker run -d --name db -e POSTGRES_PASSWORD=secret postgres:alpine
docker exec db env
docker rm -f db
```

**Exercise 8: Container Networking**
```bash
docker network create my-net
docker run -d --name app1 --network my-net nginx:alpine
docker run -d --name app2 --network my-net nginx:alpine
docker exec app1 ping app2
```

### Advanced Level

**Exercise 9: Build a Custom Image**
Create a simple web app with Dockerfile:
```dockerfile
FROM node:alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]
```

**Exercise 10: Multi-Service Application**
Create a docker-compose.yml with:
- Web frontend (nginx)
- API backend (node)
- Database (postgres)
- Cache (redis)

**Exercise 11: Docker Image Optimization**
- Use multi-stage builds
- Minimize layers
- Use .dockerignore

**Exercise 12: Persistent Data**
- Create named volumes
- Backup volume data
- Restore from backup

---

## Learning Path

### Week 1: Docker Basics
- [ ] Understand Docker architecture
- [ ] Set up the learning environment
- [ ] Run containers from existing images
- [ ] Manage container lifecycle (run, stop, start, rm)
- [ ] Work with images (pull, list, remove)
- [ ] Use basic `docker run` options (--name, -d, -p, -v)

### Week 2: Dockerfiles & Images
- [ ] Write a simple Dockerfile
- [ ] Build custom images
- [ ] Understand image layers
- [ ] Use .dockerignore
- [ ] Tag and push images to Docker Hub
- [ ] Optimize Dockerfiles

### Week 3: Storage & Networking
- [ ] Use bind mounts
- [ ] Use named volumes
- [ ] Understand volume lifecycle
- [ ] Create custom networks
- [ ] Connect containers across networks
- [ ] Understand container DNS

### Week 4: Docker Compose
- [ ] Write docker-compose.yml files
- [ ] Use services, networks, and volumes
- [ ] Start/stop multi-container apps
- [ ] Use environment variables
- [ ] Scale services
- [ ] Use depends_on and health checks

---

## Quick Reference

### Common Docker Commands

| Command | Description |
|---------|-------------|
| `docker ps` | List running containers |
| `docker ps -a` | List all containers |
| `docker images` | List images |
| `docker run` | Run a container |
| `docker exec` | Execute command in container |
| `docker stop` | Stop a container |
| `docker rm` | Remove a container |
| `docker rmi` | Remove an image |
| `docker logs` | View container logs |
| `docker inspect` | Inspect container/image |
| `docker build` | Build image from Dockerfile |
| `docker pull` | Pull image from registry |
| `docker push` | Push image to registry |

### Dockerfile Instructions

| Instruction | Description |
|-------------|-------------|
| `FROM` | Base image |
| `RUN` | Execute commands |
| `CMD` | Default command |
| `ENTRYPOINT` | Container entrypoint |
| `COPY` | Copy files |
| `ADD` | Copy + extract files |
| `ENV` | Set environment variables |
| `EXPOSE` | Document ports |
| `VOLUME` | Define mount point |
| `WORKDIR` | Set working directory |
| `USER` | Set user |

### Docker Compose Commands

| Command | Description |
|---------|-------------|
| `docker compose up` | Start services |
| `docker compose up -d` | Start detached |
| `docker compose down` | Stop and remove |
| `docker compose ps` | List services |
| `docker compose logs` | View logs |
| `docker compose exec` | Execute in service |
| `docker compose build` | Build services |
| `docker compose pull` | Pull images |

### Useful `docker run` Flags

| Flag | Description |
|------|-------------|
| `-d` | Detached mode |
| `-it` | Interactive + TTY |
| `--name` | Container name |
| `-p` | Port mapping (host:container) |
| `-v` | Volume mount |
| `--network` | Connect to network |
| `-e` | Environment variable |
| `--rm` | Auto-remove on stop |
| `--link` | Link to another container (deprecated) |

---

## Resources

- **Official Docker Documentation**: https://docs.docker.com/
- **Docker Get Started**: https://docs.docker.com/get-started/
- **Docker Compose Documentation**: https://docs.docker.com/compose/
- **Dockerfile Reference**: https://docs.docker.com/engine/reference/builder/
- **Docker Hub**: https://hub.docker.com/
- **Best Practices**: https://docs.docker.com/develop/dev-best-practices/

---

**Happy Dockerizing!**
