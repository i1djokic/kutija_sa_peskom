# GitOps Core Principles

The OpenGitOps community defines four fundamental principles that distinguish GitOps from other operational models.

## Principle 1: Declarative Configuration

The entire system — infrastructure, applications, policies, and configuration — is described **declaratively** in files.

```yaml
# Example: Declarative Kubernetes Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: app
        image: my-app:1.0.0
        ports:
        - containerPort: 8080
```

- **What** is defined, not **how** — the operator figures out the steps
- Idempotent — applying the same config produces the same result
- Machine-readable and human-readable

## Principle 2: Versioned and Immutable

Desired state is stored in Git, which provides:

- **Version history** — every change is tracked
- **Immutability** — past states are preserved
- **Audit trail** — who changed what and when

Files should be treated as immutable artifacts. To change state, update the files and commit — never modify live resources directly.

## Principle 3: Automated Reconciliation

A software agent (operator) continuously watches the Git repository and ensures the live environment matches the desired state.

```text
Reconciliation Loop:

  1. Read desired state from Git
  2. Compare with live state
  3. If different, apply changes
  4. Report status back to Git
  5. Wait and repeat (default: every 3 minutes)
```

### Drift Detection

If someone manually changes a resource (e.g., `kubectl edit deployment`), the operator detects the drift and reverts it to match the repo:

```bash
# Manual change (will be reverted)
kubectl scale deployment my-app --replicas=5

# Operator detects drift and scales back to 3
```

### Sync Strategies

| Strategy | Behavior | When to Use |
|----------|----------|-------------|
| **Automatic** | Operator syncs on every commit | CI/CD pipelines, stable environments |
| **Manual** | Operator detects drift but waits for approval | Production, compliance-heavy |
| **Scheduled** | Sync at defined intervals | Cost optimization, batch updates |

## Principle 4: Observability

The system provides continuous visibility into:

- **Sync status** — is the live state in sync with the repo?
- **Health status** — are the deployed resources healthy?
- **Drift alerts** — has something diverged?
- **Deployment history** — what was deployed and when?

Tools surface this information via:

- Web dashboards (ArgoCD UI, Flux Dashboard)
- CLI outputs (`argocd app get`, `flux reconcile`)
- Prometheus metrics
- Webhook notifications (Slack, email, PagerDuty)

```bash
# ArgoCD: Check application status
argocd app get my-app

# Output:
# Name:               my-app
# Project:            default
# Server:             https://kubernetes.default.svc
# Namespace:          my-app
# URL:                https://argocd.example.com/applications/my-app
# Repo:               https://github.com/my-org/my-app-config
# Target:             main
# Path:               ./overlays/production
# Sync Policy:        Automated
# Sync Status:        Synced
# Health Status:      Healthy
```
