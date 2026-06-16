# GitOps Tools

The GitOps ecosystem is dominated by Kubernetes-native operators. This page covers the most widely adopted tools.

## ArgoCD

[ArgoCD](https://argo-cd.readthedocs.io/) is a declarative, GitOps continuous delivery tool for Kubernetes.

| Feature | Details |
|---------|---------|
| **Type** | Pull-based operator |
| **Repo support** | Git, Helm repos, OCI |
| **Sync** | Automated or manual |
| **Multi-cluster** | Yes (hub-spoke model) |
| **UI/CLI** | Web dashboard + CLI |
| **SSO** | OIDC, Dex, Keycloak |
| **RBAC** | Project-scoped |

### Key Concepts

- **Application** — unit of deployment (repo + path + cluster + namespace)
- **Project** — logical grouping of applications with RBAC
- **Sync** — reconcile live state with desired state
- **App of Apps** — manage multiple apps from a single root app

```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Create an application
argocd app create guestbook \
  --repo https://github.com/argoproj/argocd-example-apps.git \
  --path guestbook \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default
```

## Flux

[Flux](https://fluxcd.io/) is a set of continuous delivery controllers for Kubernetes, designed around the GitOps Toolkit.

| Feature | Details |
|---------|---------|
| **Type** | Pull-based operator |
| **Repo support** | Git, Helm repos, OCI, S3, Buckets |
| **Sync** | Automated by default |
| **Multi-cluster** | Yes (Kustomize overlays) |
| **UI/CLI** | CLI + Dashboard (Weave GitOps) |
| **Dependencies** | Automatic dependency ordering |

### Key Components

- **Source Controller** — fetches artifacts from Git, Helm, OCI, S3
- **Kustomize Controller** — applies Kustomize overlays
- **Helm Controller** — manages Helm releases
- **Notification Controller** — handles events and alerts
- **Image Automation Controller** — updates images automatically

```bash
# Install Flux
flux bootstrap github \
  --owner=my-org \
  --repository=fleet-infra \
  --path=./clusters/production \
  --personal

# Add a source
flux create source git podinfo \
  --url=https://github.com/stefanprodan/podinfo \
  --branch=master \
  --interval=1m

# Create a Kustomization
flux create kustomization podinfo \
  --source=podinfo \
  --path="./kustomize" \
  --prune=true \
  --interval=5m
```

## Comparison

| Feature | ArgoCD | Flux |
|---------|--------|------|
| **Installation complexity** | Simple (single manifest) | Moderate (CLI bootstrap) |
| **Web UI** | Built-in, feature-rich | Optional (Weave GitOps) |
| **Helm support** | Good (direct + values) | Excellent (Helm Controller) |
| **Multi-cluster** | Native hub-spoke | Via Kustomize |
| **Image updates** | Third-party (Argo CD Image Updater) | Built-in |
| **RBAC** | Built-in (projects + SSO) | Via Kubernetes RBAC |
| **Community** | Large, established | Active, growing |

## Other Tools

| Tool | Description |
|------|-------------|
| **Jenkins X** | CI/CD with GitOps promotion pipelines for Kubernetes |
| **Rancher Fleet** | Scale GitOps to thousands of clusters |
| **Terraform Cloud/Enterprise** | GitOps-inspired workflow for Terraform |
| **Crossplane** | Control plane approach with GitOps patterns |
| **Sealed Secrets** | Encrypt secrets in Git repos for GitOps |

## Choosing a Tool

- **Single cluster, small team** — Flux (simpler, less moving parts)
- **Multi-cluster, enterprise** — ArgoCD (SSO, RBAC, hub-spoke)
- **Heavy Helm usage** — Flux (Helm Controller is more mature)
- **Compliance/audit heavy** — Either works; ArgoCD has better out-of-box UI
