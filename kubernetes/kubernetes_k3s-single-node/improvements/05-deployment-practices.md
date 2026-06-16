# Deployment Practices Improvements

## Issues Found

### 1. `imagePullPolicy: Always` on WordPress

**Problem**: Using `wordpress:latest` tag with `imagePullPolicy: Always` means:
- Unpredictable version bumps (latest changes at any time)
- No reproducibility — different environments may run different versions
- Potential breaking changes from MariaDB compatibility

**Fix**: Pin to a specific version:
```yaml
image: wordpress:6.7
imagePullPolicy: IfNotPresent
```

### 2. Missing Resource Limits on System Pods

**Pods without CPU limits:**

| Pod | CPU Limit | Memory Limit |
|---|---|---|
| local-path-provisioner | none | none |
| traefik | none | none |
| svclb-\* | none | none |

**Impact**: These pods can consume all node CPU/memory, starving other workloads.

**Fix**: Add resource limits:
```yaml
resources:
  limits:
    cpu: 500m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 64Mi
```

### 3. No Init Containers / Wait-for Dependencies

**Problem**: WordPress depends on MariaDB being ready, but there's no init container or startup check.

**Fix**: Add an init container:
```yaml
initContainers:
- name: wait-for-mariadb
  image: busybox:1.36
  command:
  - sh
  - -c
  - |
    until nc -z mariadb 3306; do
      echo waiting for mariadb...
      sleep 2
    done
```

### 4. No Labels/Annotations for Operational Metadata

**Problem**: Deployments lack common operational labels (e.g., `tier:`, `version:`, `managed-by:`).

**Fix**: Standardize labels:
```yaml
labels:
  app.kubernetes.io/name: wordpress
  app.kubernetes.io/instance: wordpress-demo
  app.kubernetes.io/version: "6.7"
  app.kubernetes.io/managed-by: kubectl
  app.kubernetes.io/component: frontend
  app.kubernetes.io/part-of: demo
```

### 5. Environment Variables Hardcoded

**Problem**: WordPress DB credentials are hardcoded in Deployment manifest.

**Fix**: Use existing `mariadb-secret`:
```yaml
env:
- name: WORDPRESS_DB_HOST
  value: mariadb
- name: WORDPRESS_DB_USER
  valueFrom:
    secretKeyRef:
      name: mariadb-secret
      key: username
- name: WORDPRESS_DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: mariadb-secret
      key: password
- name: WORDPRESS_DB_NAME
  valueFrom:
    secretKeyRef:
      name: mariadb-secret
      key: database
```

### 6. revisionHistoryLimit Too High

**Problem**: `revisionHistoryLimit: 10` for all user deployments. Each revision stores a full ReplicaSet spec in etcd.

**Fix**: Set `revisionHistoryLimit: 2` or `3` for most deployments.

### 7. No Service Account for WordPress/MariaDB Pods

**Problem**: These pods use the `default` service account, which may have unintended permissions via RBAC bindings.

**Fix**: Create dedicated service accounts for each application:
```bash
kubectl create sa wordpress -n demo
kubectl create sa mariadb -n demo
```

### 8. No Readiness Gates or Startup Probes

**Problem**: No `readinessGates` or `startupProbes` on user workloads. Pods are considered ready as soon as they start, not when they can serve traffic.

**Fix**: Add `startupProbe` for slow-starting apps like MariaDB:
```yaml
startupProbe:
  tcpSocket:
    port: 3306
  initialDelaySeconds: 10
  periodSeconds: 5
  failureThreshold: 30
```
