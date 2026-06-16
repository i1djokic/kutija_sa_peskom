# Argo CD — GitOps for Kubernetes

> A complete beginner's guide to deploying apps with Argo CD on this cluster.

---

## What is Argo CD?

Argo CD is a **GitOps** tool for Kubernetes. It watches a Git repository and automatically keeps your cluster in sync with what's defined in that repo. If someone changes the YAML in Git, Argo CD applies it to the cluster. If someone changes something directly on the cluster, Argo CD reverts it back to match Git.

**In plain English**: You put your Kubernetes YAML files in Git, and Argo CD makes sure the cluster always matches those files. Git is the single source of truth.

---

## How It Works (High Level)

```
┌──────────────┐     watches      ┌──────────────────────┐
│   Git Repo   │ ◄─────────────── │      Argo CD         │
│  (YAML files) │                  │  (running in K8s)    │
└──────┬───────┘                  └──────────┬───────────┘
       │                                     │
       │ push / merge                        │ apply to cluster
       │                                     ▼
       │                            ┌─────────────────┐
       └──────────────────────────► │  Kubernetes      │
                                    │  (your cluster)  │
                                    └─────────────────┘
```

---

## Step 1 — Install Argo CD on Your Cluster

SSH into your master node:

```bash
vagrant ssh master
```

Run the install command:

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Wait for all pods to be ready:

```bash
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s
kubectl get pods -n argocd
```

You should see something like:

```
NAME                                                READY   STATUS    RESTARTS
argocd-application-controller-0                     1/1     Running   0
argocd-applicationset-controller-6bdc5c8f9c-xxxxx   1/1     Running   0
argocd-dex-server-7b4f96cd5c-xxxxx                  1/1     Running   0
argocd-notifications-controller-6c9f8f9f5-xxxxx     1/1     Running   0
argocd-redis-7b8d4c7b7-xxxxx                        1/1     Running   0
argocd-repo-server-7b4f96cd5c-xxxxx                 1/1     Running   0
argocd-server-7b4f96cd5c-xxxxx                      1/1     Running   0
```

---

## Step 2 — Access the Argo CD Web UI

### Option A: Port-Forward (easiest)

From your Mac, run:

```bash
# Get the password first
vagrant ssh master -c "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"

# Then port-forward (in a separate terminal)
vagrant ssh master -c "kubectl port-forward -n argocd svc/argocd-server 8080:443 --address 0.0.0.0"
```

Then on your Mac visit: **https://192.168.64.10:8080**

- Username: `admin`
- Password: the output from the first command

**Note**: Your browser will warn about an untrusted certificate — it's self-signed, that's fine, click "Advanced → Proceed".

### Option B: Change Service to LoadBalancer / NodePort

```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
kubectl get svc argocd-server -n argocd
# Then access via http://<node-ip>:<node-port>
```

---

## Step 3 — Login via CLI (Alternative to Web UI)

From the **master** node:

```bash
# Login
argocd login 192.168.64.10:8080 --insecure

# Enter admin and the password when prompted

# Or set the password non-interactively:
ARGOCD_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)
argocd login 192.168.64.10:8080 --insecure --username admin --password "$ARGOCD_PASS"

# Update password (optional)
argocd account update-password
```

---

## Step 4 — Prepare Your Git Repo

For GitOps to work, your Kubernetes manifests need to be in a Git repository. You have two options:

### Option A: Use this project folder as a git repo

```bash
# On your Mac, from the kubernetes project root
git init
git add .
git commit -m "initial commit"

# Push to GitHub/GitLab/Bitbucket (create a repo first)
git remote add origin https://github.com/YOUR_USER/YOUR_REPO.git
git push -u origin main
```

### Option B: Use a local git server inside the VM

For testing without pushing to GitHub:

```bash
# On master node
mkdir -p /srv/git/helloworld.git && cd /srv/git/helloworld.git
git init --bare

# On your Mac, add the remote
git remote add vm ssh://vagrant@192.168.64.10:/srv/git/helloworld.git
git push vm main

# Or simpler: just use a local path in Argo CD (see Step 5)
```

---

## Step 5 — Deploy the Hello World App with Argo CD

Now the magic part. You tell Argo CD: "watch this Git path and apply what's in it."

### Create an Argo CD Application

On the **master** node, create a file called `helloworld-application.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: helloworld
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR_USER/YOUR_REPO.git   # CHANGE THIS
    targetRevision: HEAD
    path: apps/helloworld
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

> **What each field means:**
> - `source.repoURL` — Where your Git repo lives
> - `source.path` — Which folder in the repo has the Helm chart / YAML files
> - `destination.server` — Which cluster to deploy to (`kubernetes.default.svc` = this same cluster)
> - `destination.namespace` — Which namespace to deploy into
> - `syncPolicy.automated` — Auto-sync: Argo CD will automatically apply changes
> - `syncPolicy.automated.prune` — Delete resources that are removed from Git
> - `syncPolicy.automated.selfHeal` — Revert manual changes back to what's in Git

Apply it:

```bash
kubectl apply -f helloworld-application.yaml
```

### Alternative: Use the repo server directly (no remote git)

If you don't want to push to GitHub, you can configure Argo CD to read from the local filesystem on the master node:

```bash
# Register the repo server's local filesystem as a "repo"
# First, put your helloworld chart on the master:
sudo mkdir -p /apps/helloworld
# Copy from your Mac:
#   scp -P 2222 -r apps/helloworld vagrant@127.0.0.1:/apps/helloworld

# Then create Application with a local path:
```

Actually, the simplest approach for learning is to push to GitHub. Make a free GitHub repo, push this project, and use that URL.

---

## Step 6 — Watch Argo CD Do Its Thing

After applying the Application, Argo CD will:

1. Clone your Git repo
2. Read the Helm chart in `apps/helloworld/`
3. Render the templates
4. Apply them to your cluster
5. Monitor the resources and keep them in sync

Check the status:

```bash
# Via CLI
argocd app get helloworld

# Or kubectl
kubectl get applications -n argocd helloworld -o yaml

# Check the resources were actually created
kubectl get all -n default
```

In the Web UI, you'll see a visual tree of all resources with their health status (green = healthy).

---

## Step 7 — Make a Change and See GitOps in Action

1. Edit `apps/helloworld/app/index.html` on your Mac (change "Hello World!" to "Hello Argo CD!")
2. Commit and push to Git
3. Argo CD detects the change (within 3 minutes by default, or immediately if you click "Sync")
4. Argo CD builds a new Docker image and deploys it (if you changed the Dockerfile) or updates the ConfigMap

**Manual sync** (don't want to wait):

```bash
argocd app sync helloworld
```

Or click the "Sync" button in the Web UI.

---

## Key Argo CD Concepts

### Application
A running deployment. Points to a Git path and a destination cluster/namespace.

### Project
Groups applications and controls who can access them. The `default` project works for learning.

### Sync
The act of making the cluster match Git. Can be automatic or manual.

### Sync Status
- **Synced** — Cluster matches Git
- **OutOfSync** — Cluster differs from Git (Argo CD auto-fixes if self-heal is on)

### Health Status
- **Healthy** — App is running correctly
- **Degraded** — Something is broken
- **Progressing** — Rolling update or similar in progress

---

## Useful Commands

```bash
# List all applications
argocd app list

# Get app details
argocd app get helloworld

# Sync manually
argocd app sync helloworld

# Force refresh from Git
argocd app sync helloworld --force

# Delete an application
argocd app delete helloworld

# View logs
argocd app logs helloworld

# List projects
argocd proj list
```

---

## Example: Deploy via Plain YAML (Instead of Helm)

Argo CD also works with plain YAML files. If you don't want Helm, create a folder with raw Kubernetes YAML:

```yaml
# apps/helloworld-plain/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: helloworld
spec:
  replicas: 2
  selector:
    matchLabels:
      app: helloworld
  template:
    metadata:
      labels:
        app: helloworld
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: helloworld
spec:
  type: ClusterIP
  ports:
  - port: 80
  selector:
    app: helloworld
```

Then in your Application, point to that folder instead:

```yaml
spec:
  source:
    path: apps/helloworld-plain
  # no need for Helm-specific config
```

Argo CD auto-detects if it's Helm, Kustomize, or plain YAML.

---

## Troubleshooting

### "Connection refused" when Argo CD tries to clone repo
**Cause**: Repo URL is wrong or repo is private without SSH key configured.

**Fix**:
```bash
# For private repos, add SSH key
argocd repo add https://github.com/YOUR_USER/YOUR_REPO.git --ssh-private-key-file ~/.ssh/id_rsa
```

### Application stuck in "OutOfSync"
**Cause**: Something was changed on the cluster outside of Git.

**Fix**: If `selfHeal` is on, wait. Otherwise, sync manually:
```bash
argocd app sync helloworld
```

### Pods not starting after sync
**Check logs**:
```bash
kubectl describe pods -l app.kubernetes.io/name=helloworld
```

### Deleting Application leaves resources behind
If you want to clean up everything, add `--cascade`:
```bash
argocd app delete helloworld --cascade
```

---

## Uninstall Argo CD

```bash
kubectl delete namespace argocd
```

---

## Next Steps

- **Multi-cluster** — Argo CD can deploy to many clusters from one control plane
- **App of Apps pattern** — One Application that deploys many sub-applications
- **Argo Rollouts** — Advanced deployment strategies (blue-green, canary)
- **Argo Workflows** — Job orchestration on Kubernetes
- **Sealed Secrets / External Secrets** — Handle secrets safely in Git

---

## Resources

- [Argo CD Official Docs](https://argo-cd.readthedocs.io/)
- [Argo CD GitHub](https://github.com/argoproj/argo-cd)
- [GitOps Pattern](https://www.gitops.tech/)
