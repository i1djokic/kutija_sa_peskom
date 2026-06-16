# GitOps Workflow

This page describes a standard GitOps workflow using a Git repository as the single source of truth.

## Repository Structure

A typical GitOps repository organizes environments as directories or branches:

### Option A: Directory-Based (Recommended)

```
fleet-infra/
├── clusters/
│   ├── production/
│   │   ├── kustomization.yaml
│   │   └── apps/
│   └── staging/
│       ├── kustomization.yaml
│       └── apps/
├── apps/
│   ├── nginx/
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   └── redis/
│       └── ...
└── infrastructure/
    ├── monitoring/
    └── ingress/
```

### Option B: Branch-Based

```text
main branch         → production environment
staging branch       → staging environment
develop branch       → development environment
```

Branch-based is simpler but harder to manage at scale. Directory-based is more flexible (promote via PR merges).

## Standard Workflow

### 1. Developer Makes a Change

```bash
git checkout -b feature/update-nginx
# Edit files
vim apps/nginx/deployment.yaml
git add -A && git commit -m "Bump nginx to 1.25"
git push origin feature/update-nginx
```

### 2. Pull Request

Create a PR with the changes. This triggers:

- **CI pipeline** — validates YAML, runs kubeconform, checks policies
- **Code review** — team members review
- **Policy checks** — OPA/Kyverno validates compliance

```bash
# Example CI validation script
kubectl kustomize ./overlays/staging | kubeconform --strict
```

### 3. Merge to Main

When the PR merges, the GitOps operator detects the change:

```text
Push to main → Git webhook → Operator fetches new state
                              → Diff against live state
                              → Apply changes to cluster
                              → Report sync status
```

### 4. Promotion Between Environments

Promote from staging to production using a PR that copies the staging overlay to production:

```bash
git checkout -b promote-to-prod
# Copy staging config to production overlay
cp -r overlays/staging/* overlays/production/
git add -A && git commit -m "Promote staging to production"
git push origin promote-to-prod
# Open PR → review → merge
```

## Pull-Based vs Push-Based

| Aspect | Push-Based (Traditional CI/CD) | Pull-Based (GitOps) |
|--------|-------------------------------|---------------------|
| **Trigger** | CI/CD pipeline pushes to cluster | Operator pulls from Git |
| **Network** | Pipeline needs cluster access | Cluster needs Git access only |
| **Security** | Expose API to build systems | No exposed API credentials in CI |
| **Drift** | No automatic drift correction | Continuous reconciliation |
| **Latency** | Immediate (push) | Within sync interval (seconds to minutes) |

## Handling Secrets

Secrets cannot be committed in plain text. Common approaches:

```yaml
# Sealed Secrets (Bitnami)
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: my-secret
spec:
  encryptedData:
    password: AgBy3i4...encrypted...

# External Secrets Operator (recommended)
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secretsmanager
    kind: SecretStore
  target:
    name: my-secret
  data:
  - secretKey: password
    remoteRef:
      key: /production/my-app/password
```

## Disaster Recovery

To restore a cluster from scratch:

```bash
# 1. Bootstrap the GitOps operator
flux bootstrap github \
  --owner=my-org \
  --repository=fleet-infra \
  --path=./clusters/production

# 2. The operator reconciles everything from Git
#    - Namespaces, deployments, services, configmaps, secrets
#    - CRDs, operators, RBAC
#    - Monitoring, logging, ingress

# 3. Verify
flux get all
```

**Result:** A fully restored cluster in minutes with zero manual steps.
