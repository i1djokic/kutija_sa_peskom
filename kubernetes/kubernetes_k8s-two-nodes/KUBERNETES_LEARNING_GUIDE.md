# Kubernetes Learning Guide

A hands-on guide to learning Kubernetes using your local cluster (master + worker nodes).

## Table of Contents
1. [What is Kubernetes?](#what-is-kubernetes)
2. [Core Concepts](#core-concepts)
3. [Basic kubectl Commands](#basic-kubectl-commands)
4. [Pods - The Basics](#pods---the-basics)
5. [Deployments](#deployments)
6. [Services & Networking](#services--networking)
7. [ConfigMaps & Secrets](#configmaps--secrets)
8. [Persistent Storage](#persistent-storage)
9. [Namespaces](#namespaces)
10. [Practice Exercises](#practice-exercises)
11. [Learning Path](#learning-path)
12. [Quick Reference](#quick-reference)

---

## What is Kubernetes?

Kubernetes (K8s) is a container orchestration platform that automates:
- **Deployment** - Run containerized applications
- **Scaling** - Adjust number of running containers
- **Load balancing** - Distribute traffic
- **Self-healing** - Restart failed containers, replace nodes
- **Rollouts & rollbacks** - Update apps without downtime

### Your Cluster

```bash
# Connect to master
cd /path/to/kub/kubernetes
vagrant ssh master

# Check your cluster
sudo kubectl --kubeconfig=/etc/kubernetes/admin.conf get nodes
sudo kubectl --kubeconfig=/etc/kubernetes/admin.conf get pods -A
```

You have:
- **1 Master node** (control plane) - manages the cluster
- **1 Worker node** - runs your applications
- **Calico** - network plugin for pod communication

---

## Core Concepts

### Kubernetes Architecture

```
┌─────────────────────────────────────────────┐
│              Master Node                    │
│  ┌──────────────────────────────────────┐ │
│  │ API Server (kube-apiserver)         │ │
│  │ etcd (key-value store)              │ │
│  │ Scheduler (assigns pods to nodes)    │ │
│  │ Controller Manager (maintains state)  │ │
│  └──────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
         ↕ kubectl commands
┌─────────────────────────────────────────────┐
│              Worker Node                    │
│  ┌──────────────────────────────────────┐ │
│  │ kubelet (node agent)                │ │
│  │ kube-proxy (network rules)          │ │
│  │ Container Runtime (containerd)       │ │
│  │                                      │ │
│  │  ┌──────┐  ┌──────┐  ┌──────┐   │ │
│  │  │ Pod1 │  │ Pod2 │  │ Pod3 │   │ │
│  │  └──────┘  └──────┘  └──────┘   │ │
│  └──────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

### Key Objects

| Object | Purpose | Example |
|--------|---------|--------|
| **Pod** | Smallest unit, runs containers | 1-2 containers |
| **Deployment** | Manages pods, handles updates | Web app with 3 replicas |
| **Service** | Network access to pods | Load balancer for pods |
| **ConfigMap** | Configuration data | App settings |
| **Secret** | Sensitive data | Passwords, API keys |
| **Namespace** | Logical isolation | dev, staging, prod |
| **PVC** | Persistent storage claim | Database storage |

---

## Basic kubectl Commands

### Setup kubectl Alias (Optional)

```bash
# On master node
alias k='sudo kubectl --kubeconfig=/etc/kubernetes/admin.conf'
# Now use: k get pods instead of long command

# Or set KUBECONFIG
export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl get pods  # Shorter now
```

### Essential Commands

```bash
# Cluster info
kubectl cluster-info
kubectl get nodes
kubectl get nodes -o wide    # More details

# Pods
kubectl get pods
kubectl get pods -A           # All namespaces
kubectl get pods -o wide      # Show node assignment
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl exec -it <pod-name> -- /bin/bash

# Deployments
kubectl get deployments
kubectl describe deployment <deployment-name>
kubectl scale deployment <name> --replicas=3

# Services
kubectl get services
kubectl get svc -A

# All resources
kubectl get all
kubectl get all -A
```

### Output Formats

```bash
# Different output formats
kubectl get pods -o wide       # Wide format
kubectl get pods -o yaml       # YAML output
kubectl get pods -o json       # JSON output
kubectl get pods --watch       # Watch changes (Ctrl+C to stop)

# Sorting and filtering
kubectl get pods --sort-by=.metadata.name
kubectl get pods -l app=nginx  # Filter by label
```

---

## Pods - The Basics

### What is a Pod?

A Pod is the smallest deployable unit in Kubernetes. It can contain:
- 1 container (most common)
- 2+ containers (sidecar pattern)

### Create Your First Pod

```bash
# Run a simple pod (like docker run)
kubectl run nginx --image=nginx
kubectl get pods
kubectl describe pod nginx
```

### Pod Lifecycle

```bash
# Watch pod status
kubectl get pods --watch

# Statuses:
# Pending   - Not yet scheduled
# ContainerCreating - Pulling image
# Running    - Pod is running
# Succeeded  - Finished (for pods that complete)
# Failed     - Something went wrong
# CrashLoopBackOff - Keeps crashing
```

### Interact with Pod

```bash
# View logs
kubectl logs nginx
kubectl logs -f nginx    # Follow logs (Ctrl+C to stop)

# Execute commands in pod
kubectl exec nginx -- ls /
kubectl exec -it nginx -- /bin/bash    # Interactive shell
# Inside pod: exit to leave

# Copy files
kubectl cp nginx:/etc/nginx/nginx.conf ./
kubectl cp ./local-file nginx:/tmp/
```

### Delete Pod

```bash
kubectl delete pod nginx

# Force delete if stuck
kubectl delete pod nginx --force --grace-period=0
```

### Create Pod with YAML

Create `pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx:latest
    ports:
    - containerPort: 80
```

```bash
# Apply the YAML
kubectl apply -f pod.yaml

# View YAML of existing pod
kubectl get pod nginx-pod -o yaml

# Delete
kubectl delete -f pod.yaml
```

---

## Deployments

### Why Deployments?

Pods are ephemeral - they can die and won't be recreated. Deployments manage Pods and provide:
- **Replica management** - Maintain desired number of pods
- **Rolling updates** - Update without downtime
- **Rollback** - Undo bad deployments
- **Self-healing** - Replace failed pods

### Create Deployment

```bash
# Imperative way (quick)
kubectl create deployment nginx-dep --image=nginx --replicas=3

# Check
kubectl get deployments
kubectl get pods
kubectl get replicaset
```

### Deployment YAML

Create `deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
```

```bash
kubectl apply -f deployment.yaml
kubectl get deployment nginx-deployment -o wide
```

### Scaling

```bash
# Scale up
kubectl scale deployment nginx-deployment --replicas=5
kubectl get pods

# Scale down
kubectl scale deployment nginx-deployment --replicas=2
```

### Rolling Updates

```bash
# Update image (triggers rolling update)
kubectl set image deployment/nginx-deployment nginx=nginx:1.26

# Watch rollout
kubectl rollout status deployment/nginx-deployment

# View rollout history
kubectl rollout history deployment/nginx-deployment

# Undo last update
kubectl rollout undo deployment/nginx-deployment

# Undo to specific revision
kubectl rollout undo deployment/nginx-deployment --to-revision=2
```

---

## Services & Networking

### Service Types

| Type | Purpose | Example Use |
|------|---------|-------------|
| **ClusterIP** | Internal access only (default) | Database, internal APIs |
| **NodePort** | Expose on node's IP + port | Simple external access |
| **LoadBalancer** | Cloud load balancer | Production (needs cloud provider) |
| **Ingress** | HTTP/HTTPS routing | Web apps, path-based routing |

### Create Service (NodePort)

```bash
# Expose deployment
kubectl expose deployment nginx-deployment --port=80 --type=NodePort

# Check service
kubectl get svc nginx-deployment
# Note the NodePort (e.g., 80:32XXX/TCP)

# Access from your Mac (use worker node IP)
# http://192.168.56.11:32XXX
```

### Service YAML

Create `service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: NodePort
```

```bash
kubectl apply -f service.yaml
kubectl get svc nginx-service
```

### Test Connectivity

```bash
# From master node, test service
curl http://10.96.x.x:80   # ClusterIP (from inside cluster)

# Or use port-forward (temporary access from your machine)
kubectl port-forward svc/nginx-service 8080:80
# Now access: http://localhost:8080
# Press Ctrl+C to stop
```

---

## ConfigMaps & Secrets

### ConfigMap

Store non-sensitive configuration data.

```bash
# Create from literal
kubectl create configmap app-config --from-literal=color=blue --from-literal=size=large

# Create from file
echo "key=value" > config.txt
kubectl create configmap app-config --from-file=config.txt

# View
kubectl get configmaps
kubectl describe configmap app-config
kubectl get configmap app-config -o yaml
```

### Use ConfigMap in Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-config
spec:
  containers:
  - name: nginx
    image: nginx
    env:
    - name: COLOR
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: color
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
  volumes:
  - name: config-volume
    configMap:
      name: app-config
```

### Secrets

Store sensitive data (base64 encoded, not encrypted by default!).

```bash
# Create secret
kubectl create secret generic db-secret \
  --from-literal=username=admin \
  --from-literal=password=secret123

# Or from file
echo -n "admin" > username.txt
echo -n "secret123" > password.txt
kubectl create secret generic db-secret --from-file=username.txt --from-file=password.txt

# View (values are base64 encoded)
kubectl get secrets
kubectl describe secret db-secret
kubectl get secret db-secret -o yaml

# Decode
kubectl get secret db-secret -o jsonpath='{.data.username}' | base64 --decode
```

---

## Persistent Storage

### Volumes in Kubernetes

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-volume
spec:
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    emptyDir: {}   # Temporary, deleted with pod
```

### PersistentVolumeClaim (PVC)

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-pvc
spec:
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - name: storage
      mountPath: /data
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: my-pvc
```

```bash
kubectl apply -f pvc.yaml
kubectl get pvc
kubectl get pv   # PersistentVolumes (auto-created by your cluster)
```

---

## Namespaces

### Why Namespaces?

Logical isolation within a cluster:
- Separate dev/staging/prod environments
- Resource quotas per namespace
- Access control (RBAC)

### Working with Namespaces

```bash
# List namespaces
kubectl get namespaces

# Create namespace
kubectl create namespace dev
kubectl create namespace staging

# Deploy to specific namespace
kubectl apply -f deployment.yaml -n dev

# List resources in namespace
kubectl get pods -n dev
kubectl get all -n dev

# Set default namespace (temporary)
kubectl config set-context --current --namespace=dev
kubectl get pods   # Now shows pods in 'dev'

# Reset to default
kubectl config set-context --current --namespace=default
```

---

## Practice Exercises

### Beginner Level

**Exercise 1: Pod Basics**
```bash
# Create and explore a pod
kubectl run nginx --image=nginx
kubectl get pods -o wide
kubectl describe pod nginx
kubectl logs nginx
kubectl exec nginx -- ls /
kubectl delete pod nginx
```

**Exercise 2: Deployment**
```bash
# Create deployment with 3 replicas
kubectl create deployment webapp --image=nginx --replicas=3
kubectl get deployment webapp
kubectl get pods -l app=webapp

# Scale
kubectl scale deployment webapp --replicas=5
kubectl get pods

# Delete one pod and watch it recreate
kubectl delete pod <pod-name>
kubectl get pods   # Should see new pod starting
```

**Exercise 3: Service**
```bash
# Expose deployment
kubectl expose deployment webapp --port=80 --type=NodePort
kubectl get svc webapp

# Get NodePort number and access from browser
# http://192.168.56.11:<NodePort>
```

### Intermediate Level

**Exercise 4: ConfigMap & Secret**
```bash
# Create ConfigMap
kubectl create configmap app-settings \
  --from-literal=log_level=debug \
  --from-literal=max_connections=100

# Create Secret
kubectl create secret generic db-creds \
  --from-literal=db_user=admin \
  --from-literal=db_pass=s3cret

# Create pod that uses both
cat > app-pod.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  containers:
  - name: app
    image: nginx
    env:
    - name: LOG_LEVEL
      valueFrom:
        configMapKeyRef:
          name: app-settings
          key: log_level
    - name: DB_USER
      valueFrom:
        secretKeyRef:
          name: db-creds
          key: db_user
EOF

kubectl apply -f app-pod.yaml
kubectl exec app-pod -- env | grep -E "LOG_LEVEL|DB_USER"
```

**Exercise 5: Rolling Update**
```bash
# Create deployment with specific image
kubectl create deployment rollout-demo --image=nginx:1.24

# Update image
kubectl set image deployment/rollout-demo nginx=nginx:1.25

# Watch rollout
kubectl rollout status deployment/rollout-demo

# View history
kubectl rollout history deployment/rollout-demo

# Undo if something goes wrong
kubectl rollout undo deployment/rollout-demo
```

**Exercise 6: PVC**
```bash
# Create PVC
cat > pvc-exercise.yaml <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 1Gi
EOF

kubectl apply -f pvc-exercise.yaml
kubectl get pvc

# Create pod that uses PVC
cat > pod-with-pvc.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: pvc-pod
spec:
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: data-pvc
EOF

kubectl apply -f pod-with-pvc.yaml
kubectl exec pvc-pod -- sh -c "echo 'Hello' > /data/test.txt"
kubectl exec pvc-pod -- cat /data/test.txt
```

### Advanced Level

**Exercise 7: Multi-Tier App**
Deploy a web app with:
- Frontend (nginx) - 3 replicas
- Backend (simple API) - 2 replicas
- Database (mysql) - 1 replica with PVC
- Services for each tier
- ConfigMaps for configuration

**Exercise 8: Health Checks**
```bash
# Add liveness and readiness probes
cat > health-check.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: health-demo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: health-demo
  template:
    metadata:
      labels:
        app: health-demo
    spec:
      containers:
      - name: nginx
        image: nginx
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
EOF

kubectl apply -f health-check.yaml
kubectl get pods -w   # Watch health checks
```

**Exercise 9: Resource Limits**
```bash
cat > resource-demo.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: resource-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: resource-demo
  template:
    metadata:
      labels:
        app: resource-demo
    spec:
      containers:
      - name: nginx
        image: nginx
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
EOF

kubectl apply -f resource-demo.yaml
kubectl top pods   # Requires metrics-server
```

---

## Learning Path

### Week 1: Basics
- [ ] Connect to cluster (`vagrant ssh master`)
- [ ] Understand cluster architecture
- [ ] Learn basic kubectl commands
- [ ] Create and delete pods
- [ ] Understand pod lifecycle
- [ ] Use `kubectl exec`, `logs`, `describe`

### Week 2: Workloads
- [ ] Create deployments
- [ ] Scale deployments up and down
- [ ] Perform rolling updates
- [ ] Rollback deployments
- [ ] Understand ReplicaSets
- [ ] Delete collections with labels

### Week 3: Networking
- [ ] Create ClusterIP services
- [ ] Create NodePort services
- [ ] Understand service discovery (DNS)
- [ ] Use port-forwarding
- [ ] Access apps from browser
- [ ] Understand ingress (read docs)

### Week 4: Configuration
- [ ] Create ConfigMaps
- [ ] Use ConfigMaps in pods
- [ ] Create Secrets
- [ ] Use Secrets in pods
- [ ] Understand downward API
- [ ] Mount secrets as volumes

### Week 5: Storage
- [ ] Understand volume types
- [ ] Use emptyDir
- [ ] Create PVCs
- [ ] Use PVCs in pods
- [ ] Understand StorageClasses
- [ ] Test data persistence

### Week 6: Advanced Topics
- [ ] Work with namespaces
- [ ] Set resource requests/limits
- [ ] Add health checks (liveness/readiness)
- [ ] Understand init containers
- [ ] Use jobs and cronjobs
- [ ] Explore DaemonSets

### Beyond: Real-World Skills
- [ ] Helm package manager
- [ ] Ingress controllers (nginx-ingress)
- [ ] Monitoring (Prometheus/Grafana)
- [ ] Logging (ELK stack)
- [ ] CI/CD with GitLab/Jenkins
- [ ] GitOps with ArgoCD/Flux

---

## Quick Reference

### kubectl Cheat Sheet

```bash
# Pods
kubectl get pods                              # List pods
kubectl get pods -A                           # All namespaces
kubectl get pods -o wide                     # With node info
kubectl describe pod <pod>                    # Detailed info
kubectl logs <pod>                           # View logs
kubectl logs -f <pod>                        # Follow logs
kubectl exec -it <pod> -- /bin/bash         # Shell access
kubectl delete pod <pod>                     # Delete pod

# Deployments
kubectl get deployments
kubectl create deployment <name> --image=<img>
kubectl scale deployment <name> --replicas=3
kubectl set image deployment/<name> <container>=<new-image>
kubectl rollout status deployment/<name>
kubectl rollout undo deployment/<name>

# Services
kubectl get svc
kubectl expose deployment <name> --port=80 --type=NodePort
kubectl delete svc <service>

# ConfigMaps & Secrets
kubectl get configmaps
kubectl create configmap <name> --from-literal=key=value
kubectl get secrets
kubectl create secret generic <name> --from-literal=key=value

# Namespaces
kubectl get namespaces
kubectl create namespace <name>
kubectl get pods -n <namespace>

# All resources
kubectl get all
kubectl get all -A
kubectl api-resources   # List all resource types

# Context (if using kubeconfig)
kubectl config get-contexts
kubectl config use-context <context>
kubectl config set-context --current --namespace=<ns>
```

### YAML Template

```yaml
# Basic Pod
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
  labels:
    app: myapp
spec:
  containers:
  - name: mycontainer
    image: nginx:latest
    ports:
    - containerPort: 80

# Basic Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: nginx
        image: nginx:latest

# Basic Service
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  selector:
    app: myapp
  ports:
    - port: 80
      targetPort: 80
  type: ClusterIP
```

---

## Resources

### Official Documentation
- **Kubernetes Docs**: https://kubernetes.io/docs/
- **kubectl Reference**: https://kubernetes.io/docs/reference/kubectl/
- **Tutorials**: https://kubernetes.io/docs/tutorials/

### Interactive Learning
- **Katacoda**: https://www.katacoda.com/courses/kubernetes (free scenarios)
- **Play with Kubernetes**: https://labs.play-with-k8s.com/
- **KillerCoda**: https://killercoda.com/

### Books
- "Kubernetes in Action" by Marko Luksa
- "The Kubernetes Book" by Nigel Poulton
- "Kubernetes Up & Running" by Brendan Burns

### Practice
- **CKA/CKAD Exercises**: https://github.com/dgkanatsios/CKAD-exercises
- **Kubernetes the Hard Way**: https://github.com/kelseyhightower/kubernetes-the-hard-way

---

## Tips for Success

1. **Practice daily** - Even 20 minutes helps
2. **Break things** - You're learning, it's OK!
3. **Read error messages** - `kubectl describe` is your friend
4. **Use `--help`** - `kubectl run --help`
5. **Check events** - `kubectl get events --sort-by=.metadata.creationTimestamp`
6. **Use labels** - They're crucial for organization
7. **Start simple** - Master pods before deployments
8. **Document** - Keep notes of commands you learn
9. **Join community** - Kubernetes Slack, Reddit r/kubernetes
10. **Build projects** - Apply what you learn

---

## Clean Up Commands

```bash
# Delete all resources in default namespace
kubectl delete all --all

# Delete specific resources
kubectl delete deployment <name>
kubectl delete svc <name>
kubectl delete pvc <name>

# Delete namespace (and all its resources)
kubectl delete namespace <name>

# Reset cluster (nuclear option - from master)
sudo kubeadm reset -f
# Then re-init cluster
```

---

**Happy Kuberneting! 🎉**

Start now:
```bash
cd /path/to/kub/kubernetes
vagrant ssh master
sudo kubectl --kubeconfig=/etc/kubernetes/admin.conf get nodes
```
