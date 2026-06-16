# GitOps Reference

Quick reference for common GitOps commands, patterns, and configurations.

## ArgoCD CLI

```bash
# Login
argocd login <server> --sso

# Application management
argocd app create <name> --repo <url> --path <path> --dest-server <cluster>
argocd app list
argocd app get <name>
argocd app sync <name>
argocd app diff <name>
argocd app delete <name>

# Sync options
argocd app sync <name> --prune              # Remove extra resources
argocd app sync <name> --dry-run            # Preview changes
argocd app sync <name> --apply-out-of-sync-only  # Only out-of-sync resources

# Project management
argocd proj create <project>
argocd proj list
argocd proj allow-namespace <project> <namespace>

# Cluster management
argocd cluster add <context-name>

# Credentials
argocd account update-password

# Repo management
argocd repo add <url> --ssh-private-key-path <path>
argocd repo list
```

## Flux CLI

```bash
# Bootstrap
flux bootstrap github           # GitHub
flux bootstrap gitlab           # GitLab
flux bootstrap git              # Generic Git

# Source management
flux create source git <name> --url <url> --branch <branch>
flux create source helm <name> --url <url>
flux list sources
flux suspend source git <name>
flux resume source git <name>

# Kustomization management
flux create kustomization <name> --source=<source> --path=<path>
flux list kustomizations
flux reconcile kustomization <name> --with-source
flux suspend kustomization <name>

# Helm management
flux create helmrelease <name> --source=<source> --chart=<chart>
flux list helmreleases

# Image automation
flux create image repository <name> --image=<image>
flux create image policy <name> --select-semver=<range>
flux create image update <name> --git-repo=<source>

# Alerts and notifications
flux create alert-provider <name> --type=slack --channel=<channel>
flux create alert <name> --event-severity=info

# Status
flux get all
flux events
flux logs
```

## Common GitOps Patterns

### App of Apps (ArgoCD)

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app
spec:
  source:
    repoURL: https://github.com/my-org/fleet-infra.git
    path: ./apps
  destination:
    server: https://kubernetes.default.svc
  project: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Multi-Env with Kustomize (Flux)

```yaml
# clusters/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- ../../apps/nginx
- ../../apps/redis
patches:
- path: patches/replicas.yaml
  target:
    kind: Deployment
    name: nginx
```

```yaml
# patches/replicas.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 5
```

### Sync Windows

```yaml
# ArgoCD sync window (prevent deploys during blackout periods)
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: production
spec:
  syncWindows:
  - kind: deny
    schedule: "0 22 * * *"
    duration: "8h"
    applications:
    - "*-prod"
    namespaces:
    - default
```

## YAML Validation

```bash
# Validate against Kubernetes schema
kubeconform --strict deployment.yaml

# Dry run against live cluster
kubectl apply --dry-run=server -f deployment.yaml

# Lint (generic YAML + Kubernetes)
yamllint deployment.yaml

# Policy check with OPA
opa eval --data policies/ --input deployment.yaml "data.kubernetes.allow"
```

## Environment Promotion Checklist

- [ ] Config changes validated (kubeconform, yamllint)
- [ ] Secrets encrypted or referenced via External Secrets
- [ ] Image tags pinned (not `:latest`)
- [ ] Resource quotas reviewed for target environment
- [ ] Policy checks pass (OPA/Kyverno)
- [ ] Dry-run succeeded against target cluster
- [ ] PR reviewed and approved
- [ ] Monitoring and alerting configured for new resources
- [ ] Rollback plan documented
