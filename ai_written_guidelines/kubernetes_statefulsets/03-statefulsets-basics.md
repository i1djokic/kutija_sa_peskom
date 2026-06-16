# StatefulSets Basics — Managing Pods with Stable Identity

## Overview

A **StatefulSet** is a Kubernetes workload resource designed for stateful applications. Unlike Deployments, StatefulSets assign each Pod a **stable, unique identity** that persists across rescheduling and scaling events.

## Core Concepts

### 1. Stable Network Identity

Each Pod in a StatefulSet gets a hostname derived from the StatefulSet name and an ordinal index:

```
<statefulset-name>-<ordinal>.<service-name>.default.svc.cluster.local
```

Example: If you create a StatefulSet named `mysql` with 3 replicas and a headless service `mysql-svc`:

| Pod | Hostname |
|-----|----------|
| `mysql-0` | `mysql-0.mysql-svc.default.svc.cluster.local` |
| `mysql-1` | `mysql-1.mysql-svc.default.svc.cluster.local` |
| `mysql-2` | `mysql-2.mysql-svc.default.svc.cluster.local` |

When a Pod is rescheduled (e.g., node failure), it retains its **ordinal index** and hostname.

### 2. Headless Service Requirement

StatefulSets require a **headless Service** (`.spec.clusterIP: None`) to manage DNS records for individual Pods.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp-svc
  labels:
    app: myapp
spec:
  clusterIP: None    # <-- headless
  selector:
    app: myapp
  ports:
    - port: 8080
      name: http
```

### 3. Ordered Pod Management

StatefulSets create and terminate Pods in a controlled sequence:

- **Creation** (scale up): `myapp-0` → `myapp-1` → `myapp-2` — waits for each to be `Running` and `Ready` before starting the next
- **Termination** (scale down): `myapp-2` → `myapp-1` → `myapp-0` — reverse ordinal order
- **Rolling update**: updates from highest ordinal to lowest

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: myapp
spec:
  serviceName: myapp-svc       # must match headless service
  replicas: 3
  podManagementPolicy: OrderedReady  # default
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
        - name: app
          image: nginx:latest
          ports:
            - containerPort: 80
```

**`podManagementPolicy` options:**
- `OrderedReady` (default) — sequential create/update/delete
- `Parallel` — create/delete all Pods simultaneously (faster, but no ordering guarantees)

## StatefulSet vs. Deployment at a Glance

| Feature | StatefulSet | Deployment |
|---------|-------------|------------|
| Pod identity | Stable (`pod-name-0`) | Random (`deploy-7d9f8c6b4-x3k9j`) |
| Pod hostname | Predictable (via headless service) | Unpredictable |
| Storage | Each Pod gets its own PVC (via `volumeClaimTemplates`) | All Pods share the same volume/claim |
| Scaling order | Ordered by ordinal | Parallel |
| Rolling update | Ordered (highest → lowest) | Parallel, configurable |
| Use case | Databases, message queues, distributed systems | Stateless apps, web servers, APIs |

## Complete Minimal Example

```yaml
# headless service
apiVersion: v1
kind: Service
metadata:
  name: web-svc
spec:
  clusterIP: None
  selector:
    app: web
  ports:
    - port: 80

---
# statefulset
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: web-svc
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
        - name: nginx
          image: nginx:1.25
          ports:
            - containerPort: 80
          volumeMounts:
            - name: www
              mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
    - metadata:
        name: www
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 1Gi
```

## Scaling Operations

```bash
# Scale up to 5 replicas
kubectl scale statefulset web --replicas=5

# Scale down to 2 replicas (removes web-4, web-3, web-2 in order)
kubectl scale statefulset web --replicas=2
```

## Rolling Update Strategies

```yaml
spec:
  updateStrategy:
    type: RollingUpdate   # default
    rollingUpdate:
      partition: 2        # only update Pods with ordinal >= 2
```

**Canary deployments:** use `partition` to update only a subset of Pods:

```yaml
spec:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      partition: 2       # update web-2 only, keep web-0 and web-1 on old version
```

## Advanced Rolling Update Patterns

### 1. Partitioned Canary (detailed)

`partition` creates a phased rollout — only pods with **ordinal >= partition** are updated:

```yaml
spec:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      partition: 2   # web-2 gets the new spec; web-0, web-1 stay on old
```

Gradually lower `partition` to roll out to more pods:

```bash
# Roll out to web-1 as well
kubectl patch statefulset web -p '{"spec":{"updateStrategy":{"rollingUpdate":{"partition":1}}}}'

# Full rollout (all pods)
kubectl patch statefulset web -p '{"spec":{"updateStrategy":{"rollingUpdate":{"partition":0}}}}'
```

**Forced rollback:** If a bad config causes crash-loops, the controller **stalls** and won't auto-rollback. Recovery:
1. Revert `.spec.template` to the old working spec
2. **Manually delete** the broken pods — the controller recreates them with the reverted template

### 2. Blue-Green for Stateful Workloads

Native StatefulSets don't support blue-green natively. Run two StatefulSets side-by-side:

```yaml
# Old version
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres-v1
---
# New version
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres-v2
```

- Keep both running, point the headless service (or an intermediate service) at the new set
- After validation, delete the old StatefulSet and its PVCs
- Tools like **Argo Rollouts** or **Flagger** can automate this

### 3. maxUnavailable (beta since v1.35)

Controls how many pods can be down simultaneously during a rolling update:

```yaml
spec:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 2      # absolute count
      # or percentage: "10%"
```

Useful with `Parallel` pod management for faster updates.

### 4. OnDelete Strategy

Controller does nothing on spec change — you manually delete pods to trigger recreation:

```yaml
spec:
  updateStrategy:
    type: OnDelete
```

Gives full manual control over update timing and ordering.

### 5. Start Ordinal (v1.31+ stable)

Override the starting ordinal (default is 0):

```yaml
spec:
  ordinals:
    start: 100
```

Pods get ordinals `100, 101, 102...` instead of `0, 1, 2...`. Useful when running multiple StatefulSets that must coexist without ordinal collision.

## Headless Service DNS Deep Dive

### DNS Record Types

For a StatefulSet named `web` with headless service `nginx` in namespace `default`:

| Record Type | Query | Returns |
|-------------|-------|---------|
| A/AAAA | `nginx.default.svc.cluster.local` | All pod IPs (random order) |
| A/AAAA | `web-0.nginx.default.svc.cluster.local` | Single pod IP (stable identity) |
| SRV | `_http._tcp.nginx.default.svc.cluster.local` | Port + hostname for all pods |
| PTR | Reverse lookup | Pod hostname |

### SRV Records

Kubernetes automatically creates SRV records for named ports on headless services:

```bash
# Query SRV records
dig _http._tcp.nginx.default.svc.cluster.local SRV
```

```
_http._tcp.nginx.default.svc.cluster.local.
  priority 0, weight 33, port 80, target web-0.nginx.default.svc.cluster.local.
  priority 0, weight 33, port 80, target web-1.nginx.default.svc.cluster.local.
  priority 0, weight 33, port 80, target web-2.nginx.default.svc.cluster.local.
```

### Negative DNS Caching

CoreDNS caches **negative results** (NXDOMAIN) for 30 seconds by default. If you query a pod hostname before it's registered in DNS, subsequent lookups fail for 30s even after the pod is ready.

**Mitigations:**
- Reduce CoreDNS cache TTL via ConfigMap
- Use **Kubernetes API watch** or **EndpointSlice API** for time-sensitive discovery
- Use `statefulset.kubernetes.io/pod-name` label on non-headless services for direct targeting

### Label-Based Targeting

The label `statefulset.kubernetes.io/pod-name` is automatically added to each pod, enabling targeting via regular Service selectors:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mydb-0-lb
spec:
  type: LoadBalancer
  selector:
    statefulset.kubernetes.io/pod-name: postgres-0
  ports:
    - port: 5432
```

## Ordinal Index in Application Logic

### Finding Your Ordinal at Runtime

**Option A — Downward API:**
```yaml
env:
  - name: POD_NAME
    valueFrom:
      fieldRef:
        fieldPath: metadata.name
  - name: ORDINAL
    valueFrom:
      fieldRef:
        fieldPath: metadata.labels['apps.kubernetes.io/pod-index']
```

**Option B — Parse hostname:**
```bash
ORDINAL=${HOSTNAME##*-}
```

### Common Ordinal Patterns

| Pattern | Implementation |
|---------|---------------|
| Primary/replica | `ordinal == 0` → primary/leader; `ordinal > 0` → replica/follower |
| Shard assignment | `shard_id = ordinal % num_shards` |
| Gossip seed | `ordinal == 0` acts as the seed node for cluster formation |
| Data partitioning | Each pod owns partition `ordinal` of the data |
| Rank for distributed training | `rank = ordinal` for NCCL/Horovod all-reduce |

## Scaling Patterns

### Scale-Down Safeguards

- **OrderedReady**: pods terminate in **reverse ordinal order**, each must fully shut down before next
- **`terminationGracePeriodSeconds`**: must be set adequately (30s+) for applications to flush data, transfer leadership, complete in-flight operations
- **PodDisruptionBudget (PDB)**: protects quorum-based workloads:
  ```yaml
  apiVersion: policy/v1
  kind: PodDisruptionBudget
  metadata:
    name: mydb-pdb
  spec:
    minAvailable: 2   # or maxUnavailable: 1
    selector:
      matchLabels:
        app: mydb
  ```

### PVC Retention Policies (GA v1.32+)

Control whether PVCs survive scale-down or deletion:

```yaml
spec:
  persistentVolumeClaimRetentionPolicy:
    whenDeleted: Retain    # what happens when StatefulSet is deleted
    whenScaled: Retain     # what happens when scaling down
```

Options: `Retain` (default) or `Delete`. Applies only to pods removed by scaling/deletion, **not** pod failure/recreation.

### Scaling to Zero

Scale a StatefulSet to `replicas: 0` — all pods terminate in reverse order but PVCs persist (by default). Scaling back up recreates pods with same ordinal → same PVCs → data preserved. Useful for cost savings in non-production.

## Common Pitfalls & Anti-Patterns

| Pitfall | Why It's Bad | Correct Approach |
|---------|-------------|------------------|
| `terminationGracePeriodSeconds: 0` | Force-kill causes data corruption | Set 30s+ for graceful shutdown |
| Modifying `storageClassName` after creation | Immutable field — validation error | Delete STS with `--cascade=orphan`, recreate |
| Using ClusterIP Service instead of Headless | Pods aren't individually addressable | Always use `clusterIP: None` |
| Forgetting `serviceName` field | No stable DNS entries | Match `serviceName` to headless Service name |
| Expecting PVCs to auto-delete | They don't by default — orphaned volumes accumulate | Set `persistentVolumeClaimRetentionPolicy` |
| Scaling down quorum-based system without PDB | May lose quorum → cluster outage | Always use PDB with `minAvailable > N/2` |
| Using `OrderedReady` for large clusters | Sequential operations are slow | Use `Parallel` if app handles ordering |
| Relying on DNS for immediate pod discovery | Negative caching (30s delay) | Use API watcher or reduce CoreDNS TTL |
| Applying manifest overrides manual scaling | `kubectl apply` resets `replicas` to manifest value | Use `kubectl scale` or HPA |

## Key Takeaways

- StatefulSets guarantee **stable network identity** and **stable storage** per Pod
- Always need a **headless service** (`clusterIP: None`)
- Pods are created/terminated **in order** (by default)
- Use `volumeClaimTemplates` for per-Pod persistent storage
- Choose `Parallel` pod management when ordering isn't needed (improves scaling speed)
- Use `partition` for canary rollouts, not blue-green (not natively supported)
- Set `terminationGracePeriodSeconds` adequately for stateful applications
- Use PDBs to protect quorum during voluntary disruptions
- PVCs persist by default — set retention policy explicitly if you want auto-cleanup
