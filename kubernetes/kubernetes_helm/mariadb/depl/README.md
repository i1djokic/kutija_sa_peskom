# MariaDB + phpMyAdmin Deployment

## Directory Structure

```
depl/
├── 00-namespace.yaml      # Creates namespace: mariadb
├── 01-secret.yaml          # Secret with root DB password (base64 "changeme")
├── 02-mariadb.yaml         # PVC, Service (ClusterIP), Deployment for MariaDB 11.4
├── 03-phpmyadmin.yaml      # Service (LoadBalancer), Deployment for phpMyAdmin
├── 04-ingress.yaml         # Ingress for db.test → phpMyAdmin (TLS via mariadb-tls)
├── 05-tls-secret.yaml      # Static self-signed TLS secret (alternative to 06)
├── 06-tls-job.yaml         # SA + Role + RoleBinding + Job that generates TLS cert at runtime
└── kustomization.yaml      # Kustomize entry point referencing all above
```

## File Order & Dependencies

The numbered prefix (00–06) indicates the suggested apply order:

| Step | File | Depends On | Purpose |
|------|------|------------|---------|
| 1 | `00-namespace.yaml` | — | Create `mariadb` namespace |
| 2 | `01-secret.yaml` | namespace | DB root password (referenced by 02) |
| 3 | `02-mariadb.yaml` | secret | PVC, ClusterIP service, MariaDB pod |
| 4 | `03-phpmyadmin.yaml` | 02 (service `mariadb-db`) | LoadBalancer service, phpMyAdmin pod |
| 5 | `04-ingress.yaml` | 03 (service `mariadb-pma`) | HTTP ingress with TLS → phpMyAdmin |
| 6 | `05-tls-secret.yaml` **or** `06-tls-job.yaml` | — | Static TLS cert OR auto-generated cert |

> `05-tls-secret.yaml` and `06-tls-job.yaml` are **alternatives**:
> - `05` is a pre-baked static secret (apply directly).
> - `06` is a Job that generates a self-signed cert at runtime and creates the secret via kubectl. Run it **after** `04` because the Ingress references `mariadb-tls` and will fail until the secret exists.

## Deployment Methods

### Option A — Kustomize (recommended)

Only `kustomization.yaml` needs to be pointed to:

```bash
kubectl apply -k ./
```

This applies **all** resources in the order listed in `kustomization.yaml` in a single batch. Note: kustomize applies them all at once, not sequentially — if `05-tls-secret.yaml` is included, `06-tls-job.yaml` is redundant.

### Option B — Manual sequential apply

Point to individual files in order:

```bash
kubectl apply -f 00-namespace.yaml
kubectl apply -f 01-secret.yaml
kubectl apply -f 02-mariadb.yaml
kubectl apply -f 03-phpmyadmin.yaml
kubectl apply -f 04-ingress.yaml
kubectl apply -f 05-tls-secret.yaml       # static cert
# OR
kubectl apply -f 06-tls-job.yaml          # auto-generate cert, then wait for job completion
```

## Summary — What to Point to During Deployment

| Scenario | Point to |
|----------|----------|
| **Quick deploy (all-in-one)** | `kustomization.yaml` via `kubectl apply -k ./` |
| **Sequential deploy** | Each `0*.yaml` file in order (see table above) |
| **TLS via static cert** | `05-tls-secret.yaml` after step 4 |
| **TLS via auto-generated cert** | `06-tls-job.yaml` after step 4, then wait for Job to finish |

## Notes

- The Secret in `01-secret.yaml` uses a base64-encoded default password (`Y2hhbmdlbWU=` = `changeme`). **Change this before deploying to production.**
- `05-tls-secret.yaml` is a commit-time snapshot; for a real cluster you should regenerate the cert or use the Job in `06-tls-job.yaml`.
- The Ingress host is `db.test` — update this to your real domain in `04-ingress.yaml`.
