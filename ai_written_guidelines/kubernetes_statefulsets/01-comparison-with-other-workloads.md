# StatefulSet vs Other Kubernetes Workload Resources

## Overview

Kubernetes provides several workload resources. Choosing the right one depends on your application's requirements for **identity, storage, ordering, and lifecycle**.

## Comparison Matrix

| Feature | StatefulSet | Deployment | DaemonSet | Job | CronJob |
|---------|-------------|------------|-----------|-----|---------|
| **Purpose** | Stateful, ordered apps | Stateless apps | Node-level agents | Batch tasks | Scheduled tasks |
| **Pod identity** | Stable, unique (`name-N`) | Random hash | Random hash | Random hash | Random hash |
| **Ordered creation** | Yes (default) | No | No | No | No |
| **Ordered termination** | Yes (reverse) | No | No | No | No |
| **Ordered update** | Yes (highest→lowest) | Configurable (maxSurge, maxUnavailable) | Rolling update per node | N/A | N/A |
| **Per-Pod PVC** | `volumeClaimTemplates` | Not supported | Not supported | Not supported | Not supported |
| **Runs on all nodes** | No (user controls replicas) | No (scheduler decides) | Yes (one per node) | No | No |
| **Restart behavior** | Always restarts | Always restarts | Always restarts | Runs to completion | Runs to completion |
| **Scaling** | Ordered | Parallel (with strategy options) | Not applicable (node-driven) | Not applicable | Not applicable |
| **Typical count** | Fixed (3, 5, etc.) | Variable | Matches node count | 1 | 1 per execution |
| **Headless service** | Required | Not needed | Not needed | Not needed | Not needed |

## 1. StatefulSet vs Deployment

### When to use Deployment
- Stateless web servers (nginx, Apache)
- REST APIs (Node.js, Go, Python Flask)
- Worker pools that don't care about identity
- Microservices that use external databases

### When to use StatefulSet
- Databases (PostgreSQL, MySQL, MongoDB)
- Distributed systems (Cassandra, Elasticsearch, ZooKeeper)
- Message queues (Kafka, RabbitMQ, NATS)
- Anything requiring stable network identity

### Example: Deployment (stateless)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-frontend
spec:
  replicas: 5
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
```

- Pods get random names: `web-frontend-7d9f8c6b4-a1b2c`, `web-frontend-7d9f8c6b4-d3e4f`
- All Pods are identical, interchangeable
- Scaling is instant (up or down)
- Rolling update can update multiple Pods simultaneously

### Example: StatefulSet (stateful)

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres-svc
  replicas: 3
  selector:
    matchLabels:
      app: postgres
  template:
    spec:
      containers:
        - name: postgres
          image: postgres:16
          env:
            - name: POSTGRES_PASSWORD
              value: secret
          volumeMounts:
            - name: data
              mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 50Gi
```

- Pods get stable names: `postgres-0`, `postgres-1`, `postgres-2`
- Each Pod has its own persistent volume
- Pod `postgres-1` will always remount `data-postgres-1` even after rescheduling
- Rolling updates go in reverse order: `postgres-2` → `postgres-1` → `postgres-0`

## 2. StatefulSet vs DaemonSet

### When to use DaemonSet
- Log collectors (Fluentd, Filebeat, Logstash)
- Monitoring agents (Prometheus Node Exporter, Datadog Agent)
- Network proxies (kube-proxy, Cilium, Calico)
- Storage daemons (GlusterFS, Ceph)
- Node-level security agents

### Key difference
DaemonSet guarantees **exactly one Pod per node**. StatefulSet does not — you control replica count independently of node count.

### Example: DaemonSet

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
spec:
  selector:
    matchLabels:
      name: fluentd
  template:
    metadata:
      labels:
        name: fluentd
    spec:
      containers:
        - name: fluentd
          image: fluentd:v1.16
          volumeMounts:
            - name: varlog
              mountPath: /var/log
      volumes:
        - name: varlog
          hostPath:
            path: /var/log
```

### Comparison table

| Aspect | StatefulSet | DaemonSet |
|--------|-------------|-----------|
| Pod placement | `replicas` count, scheduler decides | One per node |
| Scaling | Manual (`kubectl scale`) | Automatic when nodes join/leave |
| Identity | Stable hostnames | Random |
| Storage | Per-Pod PVCs | Usually hostPath or shared volume |
| Use case | Application-level state | Node-level infrastructure |

## 3. StatefulSet vs Job / CronJob

| Aspect | StatefulSet | Job | CronJob |
|--------|-------------|-----|---------|
| **Pod lifecycle** | Long-running | Runs to completion | Scheduled runs to completion |
| **Restart** | Always | On failure only (configurable) | On failure only |
| **Completion** | Never | Yes | Yes |
| **Parallelism** | Ordered | Configurable | Configurable |
| **Use case** | Always-on services | Batch processing, DB migrations | Nightly backups, reports |

### Example: Job

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: db-migration
spec:
  backoffLimit: 3
  template:
    spec:
      containers:
        - name: migration
          image: myapp:latest
          command: ["rake", "db:migrate"]
      restartPolicy: Never
```

### Example: CronJob

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: nightly-backup
spec:
  schedule: "0 2 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: backup
              image: pg_dump:latest
              command: ["pg_dump", "-h", "postgres-0.postgres-svc", "-U", "admin", "mydb"]
          restartPolicy: Never
```

## Decision Flowchart

```
Is your application stateful? (data persists across restarts)
├── No  → Use Deployment (or DaemonSet if node-level agent)
└── Yes
    ├── Does it need stable network identity?
    │   ├── Yes → Use StatefulSet
    │   └── No
    │       └── Does it need per-Pod persistent storage?
    │           ├── Yes → Use StatefulSet (for the PVC template)
    │           └── No  → Consider Deployment with a shared volume
    └── Is it a one-time task?
        ├── Yes → Use Job (or CronJob if scheduled)
        └── No  → Use StatefulSet

Use DaemonSet when:
- You need exactly one Pod per node
- The workload is infrastructure-level (logging, monitoring, networking)

Use Job/CronJob when:
- The workload runs to completion
- It's a batch or scheduled task
```

## 4. StatefulSet vs Operator-Managed Workloads

### When to Use a Raw StatefulSet

- Simple, homogeneous workloads (single-node databases, caches, key-value stores)
- Development/staging where operational complexity isn't justified
- Applications where ordinal pod identity + persistent storage + ordered rollout is sufficient

### When to Use a Custom Operator

Operators like **Strimzi** (Kafka), **CloudNativePG** (PostgreSQL), **Cass Operator** (Cassandra), **ECK** (Elasticsearch) add domain-specific lifecycle management:

| Capability | Raw StatefulSet | Custom Operator |
|------------|----------------|-----------------|
| Pod role awareness | No (all pods identical) | Yes (primary vs replica awareness) |
| Backup/snapshot management | Manual (via CronJob) | Built-in scheduling and automation |
| Heterogeneous pod specs | No (all pods share same template) | Yes (different CPU/memory per role) |
| Volume resizing (grow + shrink) | Grow only (patch PVC manually) | Often supports shrink as well |
| AZ-aware placement | Manual via topology constraints | Automatic with zone awareness |
| Failover handling | Recreates pod on same ordinal | Leader election, primary switchover |
| Upgrade ordering | Highest→lowest ordinal | Role-aware (primary last) |
| Maintenance operations | None built-in | Automated (rebalance, repair, defrag) |

**Key limitation driving operators** (from Timescale's Popper): StatefulSets have no awareness of pod roles — during updates it may kill the primary first, triggering unnecessary failovers. Operators use an "instance matching" pattern that breaks strict ordinal ordering in favor of role-based matching.

### Decision Guide

```
Do you need domain-specific lifecycle management?
├── Yes → Use a dedicated operator (Strimzi, CNPG, ECK, etc.)
└── No
    └── Do you need stable identity + per-pod storage?
        ├── Yes → Use StatefulSet
        └── No  → Use Deployment
```

## 5. HPA and VPA with StatefulSets

### HPA (Horizontal Pod Autoscaler) — Supported

HPA can target StatefulSets natively via `scaleTargetRef`:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: StatefulSet
    name: web
  minReplicas: 3
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```

**Caveats:**
- HPA scaling happens in parallel **regardless** of pod management policy
- PVCs are **not** deleted on scale-down (unless `persistentVolumeClaimRetentionPolicy.whenScaled: Delete` is set)
- For ordered workloads, rely on application-level rebalancing (e.g., Kafka partition reassign after scale-up)
- Use `Parallel` pod management if HPA scaling speed is critical

### VPA (Vertical Pod Autoscaler) — Supported

VPA adjusts CPU/memory requests/limits on StatefulSet pods:

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: web-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: StatefulSet
    name: web
  updatePolicy:
    updateMode: Auto
  resourcePolicy:
    containerPolicies:
      - containerName: '*'
        minAllowed:
          cpu: 500m
          memory: 512Mi
        maxAllowed:
          cpu: 4
          memory: 8Gi
```

**CRITICAL:** Never run HPA and VPA on the **same metric** — they create a destabilizing feedback loop:
1. VPA increases CPU requests → utilization drops proportionally
2. HPA sees lower utilization → scales down
3. Repeat in oscillation

**Best practice:** VPA for resource right-sizing (set once), HPA for reactive scaling — but on different metrics (e.g., VPA on memory, HPA on CPU + custom metrics). Or use **KEDA** for event-driven scaling.

## 6. DaemonSet Edge Cases

### Node Fencing

`kvaps/kube-fencing` is a fencing implementation that cleans resources from failed nodes — essential for StatefulSet redundancy. When a node fails, fencing ensures stale Pods/PVCs are released so the workload can reschedule on healthy nodes. Typically deployed as a DaemonSet itself.

### Taints and Tolerations

DaemonSet pods often tolerate taints that repel normal workloads:

```yaml
tolerations:
  - operator: Exists  # tolerates ALL taints (control-plane, spot, etc.)
```

Node-level agents (monitoring, logging, CNI) commonly use this to run on control-plane nodes, spot instances, or specialized hardware.

### DaemonSet with Local Storage

- CSI node drivers, storage daemons (Ceph, Longhorn) run as DaemonSets to manage local disks per node
- Use `hostPath` or local PVs with `nodeAffinity` to pin storage
- **`volumeClaimTemplates` are NOT available in DaemonSets** — must use `hostPath` or manually created PVs

## 7. Job/CronJob with StatefulSets — Backup & Migration Patterns

### Database Backup via CronJob

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgres-backup
spec:
  schedule: "0 2 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: backup
              image: postgres:16
              command:
                - pg_dump
                - -h
                - postgres-0.postgres-svc
                - -U
                - admin
                - mydb
                - -f
                - /backup/db-$(date +%Y%m%d).sql
              volumeMounts:
                - name: backup
                  mountPath: /backup
          restartPolicy: Never
          volumes:
            - name: backup
              persistentVolumeClaim:
                claimName: backup-pvc
```

### Schema Migration Pattern

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: db-migrate
  annotations:
    argocd.argoproj.io/hook: PreSync  # for ArgoCD sync waves
spec:
  template:
    spec:
      containers:
        - name: migrate
          image: myapp:latest
          command: ["rake", "db:migrate"]
          env:
            - name: DATABASE_URL
              value: "postgres://user:pass@postgres-0.postgres-svc:5432/mydb"
      restartPolicy: Never
  backoffLimit: 2
```

### Key Considerations

- Jobs should target specific pod ordinals via DNS (`pod-0.svc`) for primary operations
- Use `ttlSecondsAfterFinished` to auto-clean completed Jobs, or they accumulate in etcd
- For large datasets, use `backoffLimit` and `activeDeadlineSeconds` to prevent runaway Jobs
- Use **Velero** for cluster-wide PV snapshot backups — works natively with StatefulSet PVCs

## 8. PodDisruptionBudget (PDB) for StatefulSets

### Configuration

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: zk-pdb
spec:
  minAvailable: 2        # at least 2 pods must be available
  # OR maxUnavailable: 1 (mutually exclusive)
  selector:
    matchLabels:
      app: zookeeper
```

### StatefulSet-Specific Guidance

| Application Type | Recommended PDB |
|-----------------|-----------------|
| Single-instance stateful | `maxUnavailable: 0` (zero voluntary evictions) |
| Quorum-based (etcd, ZK, Consul) | `maxUnavailable: 1` or `minAvailable: quorum-size` |
| Non-quorum distributed (Cassandra, Kafka) | `maxUnavailable: 1` or `minAvailable: 2` |

### Unhealthy Pod Eviction Policy (v1.31+ stable)

- `IfHealthyBudget` (default): unhealthy running pods can only be evicted if the budget is satisfied
- `AlwaysAllow`: unhealthy pods can be evicted regardless of budget — useful for draining nodes with CrashLoopBackOff pods
- Pods in `Pending`, `Succeeded`, or `Failed` phase are always considered evictable

### Critical Warning

Setting `minAvailable` too high (matching total replicas) can **block node drains indefinitely** — the drain will never complete because at least one pod must be evicted.

## 9. Topology Spread Constraints with StatefulSets

Distribute pods across failure domains:

```yaml
spec:
  template:
    spec:
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: topology.kubernetes.io/zone
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              app: postgres
```

**Multi-level spreading** (zone + hostname):

```yaml
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: DoNotSchedule
  - maxSkew: 1
    topologyKey: kubernetes.io/hostname
    whenUnsatisfiable: DoNotSchedule
```

**Important interactions:**
- Respects StatefulSet's ordered creation — pods are created sequentially but placed per spread rules
- Combined with `podAntiAffinity`, provides finer control than anti-affinity alone
- Use `matchLabelKeys` (v1.27+ beta) to filter out pods from previous revisions during rolling updates
- If a zone has zero nodes, scheduler won't consider it — use `minDomains` as workaround

## 10. StatefulSets on Spot/Preemptible Instances

### Risks

- Spot instances can be terminated with **2 minutes notice** (AWS) — can corrupt stateful data
- PVCs (RWO) are bound to a node/AZ — if spot node reclaimed, PVC may be unschedulable in another zone
- **Data loss risk**: inconsistent PV state if pod terminated mid-write

### Mitigation Strategies

| Strategy | Implementation |
|----------|---------------|
| **On-Demand for StatefulSets** | Separate node pools: `nodeSelector: lifecycle: OnDemand` for StatefulSets |
| **Label-based scheduling** | Label spot nodes `aws.amazon.com/spot: "true"`; pin StatefulSets to on-demand via `nodeSelector`/`nodeAffinity` |
| **AWS Node Termination Handler** | DaemonSet detecting Spot interruption notices — cordons node, gracefully drains pods |
| **PDB** | `maxUnavailable: 1` to prevent all replicas being disrupted simultaneously |
| **Topology Spread** | Spread across multiple AZs so one Spot reclaim doesn't take down whole cluster |
| **Volume snapshots before interruption** | Tools like Velero can snapshot within the 2-minute notice window |
| **Karpenter** | Spot + On-Demand fallback; handles interruption natively |

### Compromise for Cost-Sensitive Stateful Workloads

- Use Spot for **read-replica** StatefulSet pods (can tolerate interruption)
- Keep the **primary/write pod on On-Demand**
- Requires an operator (e.g., Zalando Postgres Operator) to manage roles — a raw StatefulSet cannot do this

## Summary

| Use Case | Best Resource |
|----------|---------------|
| Web server, REST API | Deployment |
| Database (PostgreSQL, MySQL) | StatefulSet (or operator for advanced lifecycle) |
| Distributed data store (Cassandra, Elasticsearch) | StatefulSet (or operator) |
| Message queue (Kafka, RabbitMQ) | StatefulSet (or Strimzi/operator) |
| Log collector on each node | DaemonSet |
| Monitoring agent on each node | DaemonSet |
| DB migration, one-time batch | Job |
| Nightly backup, report | CronJob |
| Node-level storage daemon | DaemonSet + hostPath |
