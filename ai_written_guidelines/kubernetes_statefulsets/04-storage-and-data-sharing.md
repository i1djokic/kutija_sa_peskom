# Storage and Data Sharing in StatefulSets

## Overview

StatefulSets provide **dedicated persistent storage per Pod** through `volumeClaimTemplates`. This is fundamentally different from Deployments, where Pods typically share a single volume or use ephemeral storage.

## 1. volumeClaimTemplates

The `volumeClaimTemplates` field generates a unique PVC for each Pod replica.

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
    metadata:
      labels:
        app: postgres
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
        storageClassName: standard
        resources:
          requests:
            storage: 10Gi
```

When applied, this creates:

| Pod | PVC | PV |
|-----|-----|----|
| `postgres-0` | `data-postgres-0` | Bound PV |
| `postgres-1` | `data-postgres-1` | Bound PV |
| `postgres-2` | `data-postgres-2` | Bound PV |

If `postgres-1` is deleted and recreated by the StatefulSet controller, it re-binds to the **same PVC** (`data-postgres-1`), preserving its data.

### PVC Naming Convention

```
<volume-claim-template-name>-<statefulset-name>-<ordinal>
```

Example: `data-postgres-1`

## 2. Sharing Data Between Pods

### Option A: ReadWriteMany (RWX) Volume

When multiple Pods need to read/write the same data, use an `accessModes: ["ReadWriteMany"]` volume backed by a shared filesystem (NFS, EFS, GlusterFS, Longhorn).

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: shared-workers
spec:
  serviceName: workers-svc
  replicas: 3
  template:
    spec:
      containers:
        - name: worker
          image: alpine
          command: ["/bin/sh", "-c"]
          args:
            - while true; do
                echo "$(hostname) processing at $(date)" >> /shared/output.log;
                sleep 10;
              done
          volumeMounts:
            - name: shared-storage
              mountPath: /shared
  volumeClaimTemplates:
    - metadata:
        name: shared-storage
      spec:
        accessModes: ["ReadWriteMany"]
        storageClassName: "efs-sc"     # depends on your cluster
        resources:
          requests:
            storage: 100Gi
```

**Warning:** When using `ReadWriteMany` with `volumeClaimTemplates`, each Pod still gets its **own** PVC. For true shared access, use a **single PVC** (not via templates) or a shared filesystem.

### Option B: Shared PVC (Not via Templates)

Manually create a single `ReadWriteMany` PVC and reference it in `spec.volumes` (not `volumeClaimTemplates`):

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-data
spec:
  accessModes: ["ReadWriteMany"]
  resources:
    requests:
      storage: 50Gi
  storageClassName: "nfs-sc"
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: workers
spec:
  serviceName: workers-svc
  replicas: 3
  template:
    spec:
      containers:
        - name: worker
          image: alpine
          volumeMounts:
            - name: shared
              mountPath: /shared
      volumes:
        - name: shared
          persistentVolumeClaim:
            claimName: shared-data   # same PVC for ALL pods
```

Now all 3 Pods mount the **same** PVC and share the same filesystem.

### Option C: Sidecar Pattern for Data Transfer

Use a sidecar container to handle data replication between Pods:

```yaml
spec:
  containers:
    - name: app
      image: my-app
      volumeMounts:
        - name: data
          mountPath: /var/data
    - name: syncer
      image: syncthing:latest
      volumeMounts:
        - name: data
          mountPath: /var/data
```

### Option D: Network-Based Replication (Stateful App)

Most stateful applications handle data sharing at the application layer:

| Application | Data Sharing Method |
|-------------|-------------------|
| **Cassandra** | Gossip protocol + hinted handoff |
| **Kafka** | Partition replication across brokers |
| **Elasticsearch** | Shard replication across nodes |
| **PostgreSQL** | Streaming replication (primary/standby) |
| **MySQL Group Replication** | Group communication protocol |

In these cases, each Pod gets its own `ReadWriteOnce` volume via `volumeClaimTemplates`, and the application handles data synchronization over the network.

## 3. Storage Class Considerations

```yaml
volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: "ssd-storage"  # use SSDs for databases
      resources:
        requests:
          storage: 100Gi
```

| Storage Class | Use Case |
|---------------|----------|
| `standard` (HDD) | Logs, backups, cold data |
| `ssd-storage` | Databases, high IOPS workloads |
| `nfs-sc` | Shared access across pods |
| `efs-sc` | AWS EFS, shared across AZs |
| `gp3-sc` | AWS gp3, balanced performance |

## 4. Resizing Persistent Volumes

```bash
# Edit the PVC to request more storage
kubectl edit pvc data-postgres-0

# Change: resources.requests.storage: 10Gi → 50Gi
```

The PV will resize automatically if the storage class supports `AllowVolumeExpansion: true`.

## 5. Manual Snapshot and Restore

```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: postgres-0-snapshot
spec:
  volumeSnapshotClassName: csi-snapshot-class
  source:
    persistentVolumeClaimName: data-postgres-0
```

```bash
# Restore from snapshot
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-postgres-0-restored
spec:
  accessModes: ["ReadWriteOnce"]
  storageClassName: standard
  resources:
    requests:
      storage: 10Gi
  dataSource:
    name: postgres-0-snapshot
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
EOF
```

## 6. Longhorn Operator — Enterprise Storage for StatefulSets

### What is Longhorn?

[Longhorn](https://longhorn.io/) is a **Kubernetes-native distributed block storage system** implemented as a Kubernetes operator. It provides:

- **Persistent volumes** for StatefulSets without external storage dependencies
- **Synchronous replication** across nodes (HA)
- **Incremental snapshots and backups** to S3/NFS
- **CSI driver** for dynamic provisioning
- **UI dashboard** for management

Longhorn itself uses **StatefulSets internally** for its engine and replica components.

### How Longhorn Works with StatefulSets

```
┌─────────────────────────────────────────────────────┐
│                 Kubernetes Cluster                   │
│                                                      │
│   ┌──────────┐  ┌──────────┐  ┌──────────┐         │
│   │StatefulSet│  │StatefulSet│  │StatefulSet│         │
│   │postgres-0 │  │postgres-1 │  │postgres-2 │         │
│   │  ┌────┐   │  │  ┌────┐   │  │  ┌────┐   │         │
│   │  │LH  │   │  │  │LH  │   │  │  │LH  │   │         │
│   │  │Engine│  │  │  │Engine│  │  │  │Engine│ │         │
│   │  └──┬─┘   │  │  └──┬─┘   │  │  └──┬─┘   │         │
│   └─────┼─────┘  └─────┼─────┘  └─────┼─────┘         │
│         │               │               │              │
│   ┌─────┴─────┐  ┌─────┴─────┐  ┌─────┴─────┐        │
│   │ Replica 1 │  │ Replica 1 │  │ Replica 1 │        │
│   │ on node-1 │  │ on node-2 │  │ on node-3 │        │
│   └───────────┘  └───────────┘  └───────────┘        │
│         │               │               │              │
│         └───────────────┼───────────────┘              │
│                         │                              │
│   ┌─────────────────────┴─────────────────────┐        │
│   │         Longhorn Manager (Operator)        │        │
│   │  - Creates engines/replicas per volume     │        │
│   │  - Handles failover and reattachment       │        │
│   │  - Manages snapshots and backups           │        │
│   └───────────────────────────────────────────┘        │
└───────────────────────────────────────────────────────┘
```

### Setting Up Longhorn

```bash
# Install Longhorn via Helm
helm repo add longhorn https://charts.longhorn.io
helm repo update
helm install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --create-namespace
```

### Configuring a StorageClass for StatefulSets

Longhorn installs a default `StorageClass` named `longhorn`. You use it in your StatefulSet's `volumeClaimTemplates`:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: longhorn-ssd
provisioner: driver.longhorn.io
allowVolumeExpansion: true
parameters:
  numberOfReplicas: "3"
  staleReplicaTimeout: "30"
  fromBackup: ""
  fsType: "ext4"
  replicaAutoBalance: "least-effort"
  dataLocality: "best-effort"
  diskSelector: "ssd"        # only use nodes with SSD disks
  nodeSelector: "storage"    # only use nodes labeled 'storage=true'
---
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
    metadata:
      labels:
        app: postgres
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
        storageClassName: longhorn-ssd    # <-- Longhorn StorageClass
        resources:
          requests:
            storage: 100Gi
```

### Longhorn Features That Benefit StatefulSets

#### 1. Cross-Node Replication (HA)

Longhorn replicates each volume across multiple nodes:

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: longhorn-ha
provisioner: driver.longhorn.io
parameters:
  numberOfReplicas: "3"        # 3 copies of every volume
  replicaAutoBalance: "least-effort"  # spread across nodes
```

When `postgres-0`'s node fails, Longhorn:
1. Detaches the volume from the dead node
2. Promotes a healthy replica on another node
3. Reattaches the volume to `postgres-0` wherever it gets rescheduled

#### 2. Volume Expansion

```bash
# Increase PVC size — Longhorn supports online expansion
kubectl edit pvc data-postgres-0
# Change: storage: 100Gi → 200Gi
# No pod restart needed if filesystem supports resize (ext4/xfs)
```

#### 3. Snapshots (Point-in-Time)

Longhorn snapshots are instantaneous (Copy-on-Write):

```bash
# Create snapshot via CLI
kubectl exec -n longhorn-system deploy/longhorn-manager -it -- \
  longhorn snapshot create data-postgres-0

# Via UI or kubectl
kubectl create -f - <<EOF
apiVersion: longhorn.io/v1beta2
kind: Volume
metadata:
  name: data-postgres-0
spec:
  snapshotMaxCount: 10
EOF
```

#### 4. Backups to S3/NFS

```bash
# Create backup target
kubectl create -f - <<EOF
apiVersion: longhorn.io/v1beta2
kind: BackupTarget
metadata:
  name: s3-backup
spec:
  backupTargetURL: "s3://my-bucket@us-east-1/"
  credentialSecret: aws-secret
EOF

# Backup a volume
kubectl exec -n longhorn-system deploy/longhorn-manager -it -- \
  longhorn backup create data-postgres-0
```

#### 5. ReadWriteMany (RWX) Support

Longhorn supports `ReadWriteMany` via its `share-manager`:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: longhorn-rwx
provisioner: driver.longhorn.io
parameters:
  numberOfReplicas: "3"
  fromBackup: ""
  migratable: "true"      # enables RWX via NFS export
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-data
spec:
  accessModes: ["ReadWriteMany"]
  storageClassName: longhorn-rwx
  resources:
    requests:
      storage: 50Gi
```

Now multiple Pods (from different StatefulSets or Deployments) can mount the same volume:

```yaml
# Shared volume mounted in multiple StatefulSet pods
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: workers
spec:
  replicas: 3
  template:
    spec:
      containers:
        - name: worker
          volumeMounts:
            - name: shared
              mountPath: /shared
      volumes:
        - name: shared
          persistentVolumeClaim:
            claimName: shared-data   # all workers mount the same PVC
```

### Longhorn vs Other Storage Operators

| Feature | Longhorn | Rook/Ceph | OpenEBS | Portworx |
|---------|----------|-----------|---------|----------|
| **Type** | Block storage | Block + Object + FS | Block storage | Block storage |
| **Replication** | Synchronous (engine + replica) | CRUSH algorithm | Jiva (sync), cStor (async) | Synchronous |
| **RWX support** | Yes (via share-manager) | Yes (CephFS) | Yes (NFS provisioner) | Yes |
| **Snapshots** | CSI snapshots + built-in | CSI snapshots | CSI snapshots | CSI snapshots + cloud |
| **Backup target** | S3, NFS, Azure Blob | S3 (via Rook) | S3, GCS | S3, Azure, GCS, pure cloud |
| **Encryption** | Volume-level encryption | OSD-level encryption | Volume-level encryption | Volume-level encryption |
| **Performance** | Good (direct I/O) | Excellent (RBD) | Moderate | Excellent |
| **Complexity** | Simple (single operator) | Complex (multiple operators) | Simple | Medium |
| **Kubernetes-native** | Yes (100% in userspace) | Yes | Yes | Yes |
| **Ideal for** | Small/medium clusters, easy HA | Large clusters, multi-region | Lightweight, edge/IoT | Enterprise, large-scale |

### Real-World Pattern: StatefulSet + Longhorn for PostgreSQL HA

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
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
          volumeMounts:
            - name: data
              mountPath: /var/lib/postgresql/data
            - name: longhorn-snap
              mountPath: /var/lib/postgresql/snapshots
      volumes:
        - name: longhorn-snap
          emptyDir: {}
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: longhorn-ha
        resources:
          requests:
            storage: 200Gi
---
# Recurring backup via Longhorn VolumeSchedule
apiVersion: longhorn.io/v1beta2
kind: VolumeSchedule
metadata:
  name: postgres-daily-backup
spec:
  recurrence: "daily"
  cron: "0 2 * * *"
  task: "backup"
  retain: 7
  labels:
    app: postgres
    type: backup
  groups:
    - "default"
```

### Key Benefits of Longhorn Operator with StatefulSets

1. **No external storage required** — uses local disks on cluster nodes
2. **3x replication** by default — survives 2 node failures
3. **Fast failover** — reattaches volumes in seconds when pods move
4. **Built-in backup** — scheduled backups to S3/NFS without extra tools
5. **GUI management** — UI for snapshots, backups, and volume operations
6. **Online expansion** — grow PVCs without pod restart
7. **Open source** — Apache 2.0 license, active community

---

## 7. Rook Ceph Operator — Enterprise Storage for StatefulSets

### What is Rook Ceph?

[Rook](https://rook.io/) is a **Kubernetes operator** that bootstraps, manages, and automates **[Ceph](https://ceph.io/)** — a distributed storage system that provides block, file, and object storage — all natively in Kubernetes.

Ceph provides three storage types relevant to StatefulSets:

| Type | Interface | Use Case |
|------|-----------|----------|
| **RBD** (RADOS Block Device) | `rbd` | RWO block volumes for StatefulSets (databases, Kafka) |
| **CephFS** | `cephfs` | RWX shared filesystem, multiple pods read/write |
| **RGW** (RADOS Gateway) | S3-compatible API | Object storage for backups, logs, artifacts |

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Kubernetes Cluster                     │
│                                                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │  StatefulSet │  │  StatefulSet │  │  StatefulSet │     │
│  │  postgres-0  │  │  postgres-1  │  │  postgres-2  │     │
│  │    ┌─────┐   │  │    ┌─────┐   │  │    ┌─────┐   │     │
│  │    │RBD  │   │  │    │RBD  │   │  │    │RBD  │   │     │
│  │    │Vol  │   │  │    │Vol  │   │  │    │Vol  │   │     │
│  │    └──┬──┘   │  │    └──┬──┘   │  │    └──┬──┘   │     │
│  └───────┼──────┘  └───────┼──────┘  └───────┼──────┘     │
│          │                 │                 │             │
│  ┌───────┴─────────────────┴─────────────────┴───────┐    │
│  │               Ceph Cluster (RADOS)                  │    │
│  │  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐   │    │
│  │  │ OSD 0  │  │ OSD 1  │  │ OSD 2  │  │ OSD 3  │   │    │
│  │  │disk-1  │  │disk-2  │  │disk-3  │  │disk-4  │   │    │
│  │  └────────┘  └────────┘  └────────┘  └────────┘   │    │
│  │  ┌─────────────────┐  ┌──────────────────────┐     │    │
│  │  │   MON (monitor)  │  │  MGR (manager)       │     │    │
│  │  └─────────────────┘  └──────────────────────┘     │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                          │
│  ┌─────────────────────────────────────────────────────┐ │
│  │           Rook Operator (rook-ceph-operator)         │ │
│  │  - Deploys & manages MON, OSD, MGR, MDS daemons     │ │
│  │  - Creates StorageClasses, PVCs, snapshots          │ │
│  │  - Automates upgrades and OSD replacement           │ │
│  └─────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

### Installation

```bash
# Deploy Rook operator and Ceph cluster
kubectl create -f https://raw.githubusercontent.com/rook/rook/release-1.14/deploy/examples/crds.yaml
kubectl create -f https://raw.githubusercontent.com/rook/rook/release-1.14/deploy/examples/common.yaml
kubectl create -f https://raw.githubusercontent.com/rook/rook/release-1.14/deploy/examples/operator.yaml

# Create a CephCluster (uses raw disks on nodes)
kubectl create -f https://raw.githubusercontent.com/rook/rook/release-1.14/deploy/examples/cluster.yaml
```

### StorageClasses for StatefulSets

#### RBD (RWO Block — Databases, Kafka)

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: rook-ceph-block
provisioner: rook-ceph.rbd.csi.ceph.com
parameters:
  clusterID: rook-ceph
  pool: replicapool
  imageFormat: "2"
  imageFeatures: layering
  csi.storage.k8s.io/fstype: ext4
  csi.storage.k8s.io/node-stage-secret-name: rook-csi-rbd-node
  csi.storage.k8s.io/node-stage-secret-namespace: rook-ceph
  csi.storage.k8s.io/controller-expand-secret-name: rook-csi-rbd-provisioner
  csi.storage.k8s.io/controller-expand-secret-namespace: rook-ceph
reclaimPolicy: Retain
allowVolumeExpansion: true
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres-svc
  replicas: 3
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
        storageClassName: rook-ceph-block
        resources:
          requests:
            storage: 100Gi
```

#### CephFS (RWX Shared — Multiple Pods)

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: rook-cephfs
provisioner: rook-ceph.cephfs.csi.ceph.com
parameters:
  clusterID: rook-ceph
  fsName: myfs
  pool: myfs-data-0
  csi.storage.k8s.io/controller-expand-secret-name: rook-csi-cephfs-provisioner
  csi.storage.k8s.io/controller-expand-secret-namespace: rook-ceph
reclaimPolicy: Retain
allowVolumeExpansion: true
---
# Shared PVC — all StatefulSet pods mount the same volume
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-data
spec:
  accessModes: ["ReadWriteMany"]
  storageClassName: rook-cephfs
  resources:
    requests:
      storage: 500Gi
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: ml-workers
spec:
  serviceName: workers-svc
  replicas: 3
  selector:
    matchLabels:
      app: ml-worker
  template:
    metadata:
      labels:
        app: ml-worker
    spec:
      containers:
        - name: worker
          image: tensorflow/tensorflow:latest
          command: ["python", "train.py"]
          volumeMounts:
            - name: shared
              mountPath: /data
      volumes:
        - name: shared
          persistentVolumeClaim:
            claimName: shared-data
```

### Rook Ceph Features for StatefulSets

#### 1. Replication (CRUSH Algorithm)

Ceph uses the **CRUSH** algorithm for data placement and replication — no central metadata server:

```yaml
apiVersion: ceph.rook.io/v1
kind: CephBlockPool
metadata:
  name: replicapool
  namespace: rook-ceph
spec:
  failureDomain: host       # replicate across hosts
  replicated:
    size: 3                  # 3 copies of every block
    requireSafeReplicaSize: true
  mirroring:
    enabled: true            # enable RBD mirroring for DR
    mode: pool               # journal-based mirroring
```

#### 2. Snapshots via CSI

```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: ceph-rbd-snap
driver: rook-ceph.rbd.csi.ceph.com
parameters:
  clusterID: rook-ceph
  csi.storage.k8s.io/snapshotter-secret-name: rook-csi-rbd-provisioner
  csi.storage.k8s.io/snapshotter-secret-namespace: rook-ceph
---
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: postgres-0-pre-upgrade
spec:
  volumeSnapshotClassName: ceph-rbd-snap
  source:
    persistentVolumeClaimName: data-postgres-0
```

#### 3. Thin Provisioning

Ceph RBD volumes are thin-provisioned — you can request 100Gi but only consume actual used space. Overcommit is configurable:

```yaml
apiVersion: ceph.rook.io/v1
kind: CephBlockPool
metadata:
  name: replicapool
spec:
  replicated:
    size: 3
  quotas:
    maxSize: 10Ti            # pool-level limit
```

#### 4. RBD Mirroring (Disaster Recovery)

Cross-cluster mirroring for DR:

```bash
# Enable mirroring on a pool
kubectl exec -n rook-ceph deploy/rook-ceph-operator -- \
  rbd mirror pool enable replicapool image

# Promote a mirrored image on DR cluster in disaster
kubectl exec -n rook-ceph deploy/rook-ceph-operator -- \
  rbd mirror image promote data-postgres-0
```

### Real-World Pattern: StatefulSet + Ceph for Kafka

```yaml
apiVersion: ceph.rook.io/v1
kind: CephBlockPool
metadata:
  name: kafka-pool
  namespace: rook-ceph
spec:
  failureDomain: host
  replicated:
    size: 3
  parameters:
    compression_mode: aggressive   # compress Kafka log data
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: rook-ceph-kafka
provisioner: rook-ceph.rbd.csi.ceph.com
parameters:
  clusterID: rook-ceph
  pool: kafka-pool
  imageFeatures: layering,fast-diff,object-map,deep-flatten,exclusive-lock
  csi.storage.k8s.io/fstype: xfs      # XFS is recommended for Kafka
  mountOptions: "noatime,nodiratime"   # optimize for throughput
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: kafka
spec:
  serviceName: kafka-svc
  replicas: 3
  selector:
    matchLabels:
      app: kafka
  template:
    spec:
      containers:
        - name: kafka
          image: confluentinc/cp-kafka:7.6
          env:
            - name: KAFKA_BROKER_ID
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: KAFKA_ADVERTISED_LISTENERS
              value: "PLAINTEXT://$(POD_NAME).kafka-svc:9092"
            - name: KAFKA_LOG_DIRS
              value: /var/lib/kafka/data
          volumeMounts:
            - name: data
              mountPath: /var/lib/kafka/data
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: rook-ceph-kafka
        resources:
          requests:
            storage: 1Ti
```

### Comparison: Longhorn vs Rook Ceph

| Feature | Longhorn | Rook Ceph |
|---------|----------|-----------|
| **Architecture** | Engine + replica per volume | CRUSH + OSD + MON + MGR |
| **Replication** | 1 engine + N replicas (sync) | CRUSH-based, configurable size |
| **Performance** | Good (direct I/O to local disk) | Excellent (RBD kernel module) |
| **RWX** | Via share-manager (NFS) | Native CephFS (POSIX-compliant) |
| **Object storage** | No (backups only) | Yes (RGW, S3-compatible) |
| **Resource usage** | Lower (lightweight engine per vol) | Higher (MON, MGR, MDS daemons) |
| **Operational complexity** | Low (single operator) | Medium-High (multiple CRDs) |
| **Maturity** | 2019+ (CNCF incubating) | 2016+ (CNCF graduated) |
| **Backup target** | S3, NFS, Azure | S3, NFS, Azure (via RGW) |
| **Encryption** | Volume-level | OSD-level + volume-level |
| **Disk requirements** | Any (partition or block) | Raw block device (unformatted) |
| **Ideal for** | Small/medium clusters, easy ops | Large clusters, multi-region, object storage |

### When to Use Which

```
Is your cluster small (< 10 nodes)?
├── Yes → Use Longhorn (simpler, lower overhead)
└── No
    ├── Do you need S3-compatible object storage?
    │   ├── Yes → Use Rook Ceph (built-in RGW)
    │   └── No
    │       └── Do you need high IOPS?
    │           ├── Yes → Use Rook Ceph (RBD kernel module)
    │           └── No  → Use Longhorn or Rook Ceph
    └── Do you already have raw block devices on nodes?
        ├── Yes → Rook Ceph (designed for raw devices)
        └── No  → Longhorn (works on any mounted path)
```

## 8. Cleaning Up

**Important:** Deleting a StatefulSet does **NOT** delete the PVCs by default. You must manually clean them up:

```bash
# Delete the StatefulSet but keep PVCs (default)
kubectl delete statefulset postgres

# Delete everything including PVCs
kubectl delete statefulset postgres
kubectl delete pvc -l app=postgres
# Or with cascading deletion policy (supported in newer versions)
kubectl delete statefulset postgres --cascade=orphan
```

## 8. Topology-Aware Provisioning

### CSI Topology (GA since K8s 1.17)

CSI drivers report `accessible_topology` via `NodeGetInfoResponse`. Kubernetes uses `WaitForFirstConsumer` to provision volumes in the same zone as the pod:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: topology-aware
provisioner: driver.longhorn.io
volumeBindingMode: WaitForFirstConsumer  # critical for topology
parameters:
  numberOfReplicas: "3"
```

### Longhorn Topology

- Writes `nodeAffinity` rules into PVs at creation time
- Pins volumes to specific zones/regions
- Works with `volumeBindingMode: WaitForFirstConsumer`
- Compatible with `allowedTopologies` in StorageClass

### Node Affinity for Storage

```yaml
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: topology.kubernetes.io/zone
              operator: In
              values:
                - us-east-1a
```

### Topology-Aware Routing (K8s 1.33+ GA)

Keep traffic within zone using `service.kubernetes.io/topology-mode: Auto` — reduces cross-AZ data transfer costs and latency.

## 9. Encryption at Rest and In Transit

### Longhorn Volume Encryption

Uses Linux `dm_crypt` + `cryptsetup` (LUKS2):

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: longhorn-crypto
  namespace: longhorn-system
stringData:
  CRYPTO_KEY_VALUE: "your-encryption-passphrase"
  CRYPTO_KEY_PROVIDER: "secret"
```

- Algorithm: `aes-xts-plain64`, key size: 256, hash: `sha256`, PBKDF: `argon2i`
- Encryption key stored in Kubernetes Secret
- Backups from encrypted volumes are also encrypted
- `dm_crypt` kernel module must be loaded on all worker nodes
- **V2 Data Engine does not yet support volume encryption**

### Ceph (Rook) Encryption

- **OSD-level encryption**: `dmcrypt` + LUKSv1, enabled during OSD creation (`encryptedDevice: "true"`)
- Transparent to clients — encrypted at the OSD level
- **In-transit**: Ceph Messenger v2 supports `ms_cluster_mode: secure` / `ms_service_mode: secure`
- Encrypts data between OSDs, MONs, and clients

### In-Transit Encryption Comparison

| Storage Operator | In Transit | At Rest |
|-----------------|------------|---------|
| Longhorn | mTLS between components | `dm_crypt` LUKS2 |
| Rook Ceph | Msgr2 (msgr v2 protocol) | `dmcrypt` LUKSv1 (OSD-level) |
| Cloud (EBS/CSI) | Provider network encryption | KMS-managed keys |

### Kubernetes-Level Encryption

```yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources: ["secrets"]
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: <base64-32-byte-key>
      - identity: {}
```

## 10. Cost Optimization with StatefulSet Storage

### Thin Provisioning

| Operator | Setting | Recommendation |
|----------|---------|---------------|
| Longhorn | `overprovisioning-percentage` | 200% if volumes avg 50% usage |
| Longhorn | `minimal-available-storage-percentage` | 10% for dedicated disks, 25% for root disks |

**Risk**: Disk-full scenarios require monitoring — Longhorn emits events when approaching capacity.

### Reclaim Policies

| Policy | Behavior | Use Case |
|--------|----------|----------|
| `Delete` | PV + backend destroyed when PVC deleted | Dev/test, ephemeral |
| `Retain` | PV preserved for manual recovery | Production databases |

Production StatefulSets should use `Retain` or have backups before using `Delete`.

### Storage Tiers with Disk Selectors

```yaml
parameters:
  nodeSelector: "ssd-node,fast-disk"
  diskSelector: "nvme"
  storageTag: ["fast", "hdd"]
```

Group NVMe disks separately from HDDs; assign different StorageClasses:

| Tier | Disk | StorageClass | Use Case |
|------|------|-------------|----------|
| Hot | NVMe | `longhorn-hot` | Databases, Kafka |
| Warm | SSD | `longhorn-standard` | General workloads |
| Cold | HDD | `longhorn-cold` | Backups, logs, archives |

### Garbage Collection & Cleanup

- **Longhorn snapshots**: system-generated (replica rebuild) + user-created snapshots consume space — schedule recurring cleanup
- **Filesystem trim**: periodic `fstrim` via `TrimFilesystem` setting reclaims freed space inside volumes
- **Orphaned data**: unused PVCs, PVs in `Released` state — set up automated monitoring
- **35–50% of K8s spend is wasted** on unattached PVs, idle resources, zombie deployments — audit regularly

### Replica Count vs Cost

| Replicas | Storage Overhead | Fault Tolerance | Use When |
|----------|-----------------|-----------------|----------|
| 1 (strict-local) | 1x | None | App handles replication (distributed DBs) |
| 2 | 2x | 1 node failure | Dev/staging, cost-sensitive prod |
| 3 (default) | 3x | 2 node failures | Production — recommended |

### Cross-AZ Traffic

Topology-aware routing (`service.kubernetes.io/topology-mode: Auto`) reduces cross-AZ data transfer costs. Zone-local traffic incurs no cross-AZ charges (AWS/GCP/Azure).

## Key Takeaways

- `volumeClaimTemplates` creates **one unique PVC per Pod replica**
- PVCs survive Pod deletion — data persists across rescheduling
- For **shared data across Pods**, use `ReadWriteMany` volumes or application-level replication
- PVC names follow: `<template-name>-<statefulset-name>-<ordinal>`
- Deleting a StatefulSet does **not** delete PVCs automatically
- Use `VolumeSnapshot` CSI for backup/restore
- **Topology-aware provisioning** with `WaitForFirstConsumer` places data in the same zone as pods
- **Longhorn encrypts** volumes via `dm_crypt` LUKS2; **Ceph** encrypts at OSD level and in transit via Msgr2
- **Cost optimization**: thin provisioning, right-size PVCs, use storage tiers, audit orphaned volumes, balance replica count against fault tolerance
