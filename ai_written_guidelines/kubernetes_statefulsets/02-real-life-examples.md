# Real-Life StatefulSet Examples and Use Cases

## 1. PostgreSQL Primary-Replica Cluster

### Scenario
Run a PostgreSQL cluster with one primary (writes) and two read replicas. Each Pod has its own persistent volume. Applications write to the primary and read from replicas.

### Architecture

```
                    ┌─────────────────┐
                    │   Application   │
                    └───────┬─────────┘
                            │
                    ┌───────┴─────────┐
                    │   pgpool-svc    │  (regular ClusterIP Service)
                    │   Load Balancer │
                    └─┬────┬────┬─────┘
                      │    │    │
         ┌────────────┘    │    └────────────┐
         ▼                 ▼                 ▼
   ┌──────────┐      ┌──────────┐      ┌──────────┐
   │postgres-0│◄────►│postgres-1│◄────►│postgres-2│
   │ PRIMARY  │      │ REPLICA  │      │ REPLICA  │
   │   PVC    │      │   PVC    │      │   PVC    │
   └──────────┘      └──────────┘      └──────────┘
         │                 │                 │
   ┌─────┴─────┐    ┌─────┴─────┐    ┌─────┴─────┐
   │data-pg-0  │    │data-pg-1  │    │data-pg-2  │
   └───────────┘    └───────────┘    └───────────┘
```

### Implementation

**Headless Service** (for Pod DNS):
```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres-svc
spec:
  clusterIP: None
  selector:
    app: postgres
  ports:
    - port: 5432
      name: postgres
```

**StatefulSet:**
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
              valueFrom:
                secretKeyRef:
                  name: pg-secret
                  key: password
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: POSTGRES_REPLICATION_MODE
              value: "$(POD_NAME)" # scripts use this to determine primary/replica
          ports:
            - containerPort: 5432
          volumeMounts:
            - name: data
              mountPath: /var/lib/postgresql/data
      initContainers:
        - name: init-replication
          image: postgres:16
          env:
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
          command:
            - "/bin/sh"
            - "-c"
            - |
              if [ "$POD_NAME" = "postgres-0" ]; then
                # Initialize as primary
                echo "Initializing as primary"
              else
                # Clone from postgres-0
                pg_basebackup -h postgres-0.postgres-svc -D /var/lib/postgresql/data -P -U replicator
              fi
          volumeMounts:
            - name: data
              mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: ssd-storage
        resources:
          requests:
            storage: 100Gi
```

**Read Service:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres-read
spec:
  selector:
    app: postgres
  ports:
    - port: 5432
```

### Operations

```bash
# Scale replicas
kubectl scale statefulset postgres --replicas=5

# Failover: promote replica to primary
kubectl exec postgres-1 -- pg_ctl promote

# Resize volume
kubectl edit pvc data-postgres-0
# Change: storage: 100Gi → 200Gi
```

## 2. Apache Kafka Cluster

### Scenario
A 3-broker Kafka cluster with ZooKeeper (also a StatefulSet). Each broker gets its own data volume. Topics are partitioned and replicated across brokers.

### Architecture

```
            ┌──────────────────────────────┐
            │       Kafka Cluster          │
            │  ┌──────┐  ┌──────┐  ┌──────┐│
            │  │kafka-0│  │kafka-1│  │kafka-2││
            │  │BROKER1│  │BROKER2│  │BROKER3││
            │  └──┬───┘  └──┬───┘  └──┬───┘│
            │     │          │          │     │
            │  ┌──┴───┐  ┌──┴───┐  ┌──┴───┐ │
            │  │pv-0  │  │pv-1  │  │pv-2  │ │
            │  └──────┘  └──────┘  └──────┘ │
            └──────────────────────────────┘
                        │
            ┌───────────┴───────────┐
            │   ZooKeeper Ensemble   │
            │  ┌──────┐  ┌──────┐  ┌──────┐│
            │  │zk-0  │  │zk-1  │  │zk-2  ││
            │  └──────┘  └──────┘  └──────┘│
            └──────────────────────────────┘
```

### Implementation

**Kafka StatefulSet:**
```yaml
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
    metadata:
      labels:
        app: kafka
    spec:
      containers:
        - name: kafka
          image: confluentinc/cp-kafka:7.6
          env:
            - name: KAFKA_BROKER_ID
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name   # kafka-0, kafka-1, kafka-2
            - name: KAFKA_ZOOKEEPER_CONNECT
              value: "zk-0.zk-svc:2181,zk-1.zk-svc:2181,zk-2.zk-svc:2181"
            - name: KAFKA_ADVERTISED_LISTENERS
              value: "PLAINTEXT://$(POD_NAME).kafka-svc:9092"
            - name: KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR
              value: "3"
            - name: KAFKA_DEFAULT_REPLICATION_FACTOR
              value: "3"
          ports:
            - containerPort: 9092
          volumeMounts:
            - name: data
              mountPath: /var/lib/kafka/data
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: ssd-storage
        resources:
          requests:
            storage: 500Gi
```

### Operations

```bash
# Create a topic with replication
kubectl exec kafka-0 -- kafka-topics --create \
  --topic orders \
  --partitions 6 \
  --replication-factor 3 \
  --bootstrap-server localhost:9092

# Rebalance if scaling
kubectl scale statefulset kafka --replicas=6
# Then use kafka-reassign-partitions to rebalance

# Check broker status
kubectl exec kafka-0 -- kafka-broker-api-versions --bootstrap-server localhost:9092
```

**ZooKeeper StatefulSet:**
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: zk
spec:
  serviceName: zk-svc
  replicas: 3
  selector:
    matchLabels:
      app: zk
  template:
    spec:
      containers:
        - name: zk
          image: confluentinc/cp-zookeeper:7.6
          env:
            - name: ZOOKEEPER_SERVER_ID
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: ZOOKEEPER_SERVERS
              value: "zk-0.zk-svc:2888:3888;zk-1.zk-svc:2888:3888;zk-2.zk-svc:2888:3888"
          volumeMounts:
            - name: data
              mountPath: /var/lib/zookeeper/data
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 50Gi
```

## 3. Elasticsearch Cluster

### Scenario
A 3-node Elasticsearch cluster for log aggregation. Each node is a data+master node. Pods discover each other through DNS.

### Implementation

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: es
spec:
  serviceName: es-svc
  replicas: 3
  selector:
    matchLabels:
      app: elasticsearch
  template:
    metadata:
      labels:
        app: elasticsearch
    spec:
      containers:
        - name: elasticsearch
          image: docker.elastic.co/elasticsearch/elasticsearch:8.13
          env:
            - name: node.name
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: cluster.name
              value: "logs-cluster"
            - name: discovery.seed_hosts
              value: "es-0.es-svc,es-1.es-svc,es-2.es-svc"
            - name: cluster.initial_master_nodes
              value: "es-0,es-1,es-2"
            - name: ES_JAVA_OPTS
              value: "-Xms2g -Xmx2g"
            - name: xpack.security.enabled
              value: "false"
          ports:
            - containerPort: 9200
              name: http
            - containerPort: 9300
              name: transport
          volumeMounts:
            - name: data
              mountPath: /usr/share/elasticsearch/data
      initContainers:
        - name: fix-permissions
          image: busybox
          command: ["chown", "-R", "1000:1000", "/usr/share/elasticsearch/data"]
          volumeMounts:
            - name: data
              mountPath: /usr/share/elasticsearch/data
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: ssd-storage
        resources:
          requests:
            storage: 200Gi
```

### Operations

```bash
# Check cluster health
kubectl exec es-0 -- curl -s http://localhost:9200/_cluster/health

# List indices
kubectl exec es-0 -- curl -s http://localhost:9200/_cat/indices

# Add a node to the cluster
kubectl scale statefulset es --replicas=5
# Elasticsearch auto-discovers new nodes via seed hosts
```

## 4. MongoDB Replica Set

### Scenario
A 3-member MongoDB replica set with one primary and two secondaries. Data is replicated automatically.

### Implementation

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mongo
spec:
  serviceName: mongo-svc
  replicas: 3
  selector:
    matchLabels:
      app: mongo
  template:
    metadata:
      labels:
        app: mongo
    spec:
      containers:
        - name: mongo
          image: mongo:7
          command:
            - mongod
            - "--replSet"
            - rs0
            - "--bind_ip_all"
          ports:
            - containerPort: 27017
          volumeMounts:
            - name: data
              mountPath: /data/db
      initContainers:
        - name: init-mongo
          image: mongo:7
          command:
            - bash
            - -c
            - |
              if [ "$(hostname)" = "mongo-0" ]; then
                # Initialize replica set
                mongosh --eval "
                  rs.initiate({
                    _id: 'rs0',
                    members: [
                      { _id: 0, host: 'mongo-0.mongo-svc:27017' },
                      { _id: 1, host: 'mongo-1.mongo-svc:27017' },
                      { _id: 2, host: 'mongo-2.mongo-svc:27017' }
                    ]
                  })
                "
              fi
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: ssd-storage
        resources:
          requests:
            storage: 100Gi
```

### Operations

```bash
# Check replica set status
kubectl exec mongo-0 -- mongosh --eval "rs.status()"

# Step down primary
kubectl exec mongo-0 -- mongosh --eval "rs.stepDown()"

# Add new member
kubectl scale statefulset mongo --replicas=4
kubectl exec mongo-0 -- mongosh --eval "rs.add('mongo-3.mongo-svc:27017')"
```

## 5. RabbitMQ Cluster

### Scenario
A 3-node RabbitMQ cluster with mirrored queues. Nodes discover each other via DNS.

### Implementation

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: rabbitmq
spec:
  serviceName: rabbitmq-svc
  replicas: 3
  selector:
    matchLabels:
      app: rabbitmq
  template:
    metadata:
      labels:
        app: rabbitmq
    spec:
      containers:
        - name: rabbitmq
          image: rabbitmq:3.13-management
          env:
            - name: RABBITMQ_NODENAME
              value: "rabbit@$(hostname).rabbitmq-svc"
            - name: RABBITMQ_USE_LONGNAME
              value: "true"
            - name: RABBITMQ_ERLANG_COOKIE
              valueFrom:
                secretKeyRef:
                  name: rabbitmq-secret
                  key: erlang-cookie
            - name: K8S_HOSTNAME_SUFFIX
              value: ".rabbitmq-svc"
            - name: RABBITMQ_CLUSTER_FORMATION_K8S_ADDRESS_TYPE
              value: "hostname"
          ports:
            - containerPort: 5672
              name: amqp
            - containerPort: 15672
              name: management
          volumeMounts:
            - name: data
              mountPath: /var/lib/rabbitmq
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: standard
        resources:
          requests:
            storage: 50Gi
```

## 6. Cassandra Ring

### Scenario
A 4-node Cassandra ring with replication factor 3. Data is partitioned and replicated across nodes.

### Implementation

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: cassandra
spec:
  serviceName: cassandra-svc
  replicas: 4
  selector:
    matchLabels:
      app: cassandra
  template:
    metadata:
      labels:
        app: cassandra
    spec:
      containers:
        - name: cassandra
          image: cassandra:5.0
          env:
            - name: CASSANDRA_SEEDS
              value: "cassandra-0.cassandra-svc"
            - name: CASSANDRA_CLUSTER_NAME
              value: "MyCluster"
            - name: CASSANDRA_DC
              value: "DC1"
            - name: CASSANDRA_RACK
              value: "RACK1"
            - name: POD_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
            - name: CASSANDRA_BROADCAST_ADDRESS
              value: "$(POD_IP)"
          ports:
            - containerPort: 9042
              name: cql
          volumeMounts:
            - name: data
              mountPath: /var/lib/cassandra/data
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: ssd-storage
        resources:
          requests:
            storage: 500Gi
```

### Operations

```bash
# Check ring status
kubectl exec cassandra-0 -- nodetool status

# Repair
kubectl exec cassandra-0 -- nodetool repair mykeyspace

# Decommission a node
kubectl exec cassandra-3 -- nodetool decommission
kubectl delete pod cassandra-3
kubectl scale statefulset cassandra --replicas=3
```

## 7. Key-Value Store (etcd)

### Scenario
A 3-node etcd cluster for Kubernetes control plane or service discovery.

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: etcd
spec:
  serviceName: etcd-svc
  replicas: 3
  selector:
    matchLabels:
      app: etcd
  template:
    spec:
      containers:
        - name: etcd
          image: gcr.io/etcd-development/etcd:v3.5
          env:
            - name: ETCD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: ETCD_INITIAL_CLUSTER
              value: "etcd-0=http://etcd-0.etcd-svc:2380,etcd-1=http://etcd-1.etcd-svc:2380,etcd-2=http://etcd-2.etcd-svc:2380"
            - name: ETCD_INITIAL_ADVERTISE_PEER_URLS
              value: "http://$(HOSTNAME).etcd-svc:2380"
            - name: ETCD_ADVERTISE_CLIENT_URLS
              value: "http://$(HOSTNAME).etcd-svc:2379"
            - name: ETCD_LISTEN_CLIENT_URLS
              value: "http://0.0.0.0:2379"
            - name: ETCD_LISTEN_PEER_URLS
              value: "http://0.0.0.0:2380"
            - name: ETCD_DATA_DIR
              value: "/var/lib/etcd"
          volumeMounts:
            - name: data
              mountPath: /var/lib/etcd
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: ssd-storage
        resources:
          requests:
            storage: 10Gi
```

## Real-World Comparison Table

| Application | Replicas | Storage | Data Sharing | Scaling Pattern |
|-------------|----------|---------|--------------|-----------------|
| PostgreSQL | 3-5 | RWO, 100GB+ per node | Streaming replication | Manual (add replicas) |
| Kafka | 3-6 | RWO, 500GB+ per broker | Topic partitioning | Manual + reassign partitions |
| Elasticsearch | 3-20 | RWO, 1TB+ per node | Shard replication | Auto-rebalancing |
| Cassandra | 3-12 | RWO, 1TB+ per node | Gossip + replication | Auto (virtual nodes) |
| MongoDB | 3-7 | RWO, 500GB+ per node | Oplog replication | Manual + reconfig |
| RabbitMQ | 3-5 | RWO, 50GB+ per node | Queue mirroring | Manual |
| ZooKeeper | 3-5 | RWO, 10GB+ per node | ZAB protocol | Manual (odd number) |
| etcd | 3-5 | RWO, 10GB+ per node | Raft consensus | Manual (odd number) |

## 8. Redis Cluster (Sentinel HA)

### Scenario
A 3-node Redis cluster with Sentinel for high availability. One primary, two replicas, and three sentinels for quorum-based failover.

### Implementation

```yaml
# Redis StatefulSet (primary + replicas)
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: redis
spec:
  serviceName: redis-svc
  replicas: 3
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
        - name: redis
          image: redis:7.2
          command: ["redis-server"]
          args:
            - "--appendonly"
            - "yes"
            - "--replica-announce-ip"
            - "$(POD_IP)"
          env:
            - name: POD_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
          ports:
            - containerPort: 6379
          volumeMounts:
            - name: data
              mountPath: /data
          resources:
            requests:
              memory: 256Mi
              cpu: 100m
            limits:
              memory: 1Gi
              cpu: 500m
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: ssd-storage
        resources:
          requests:
            storage: 8Gi
---
# Sentinel StatefulSet
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: redis-sentinel
spec:
  serviceName: sentinel-svc
  replicas: 3
  selector:
    matchLabels:
      app: redis-sentinel
  template:
    metadata:
      labels:
        app: redis-sentinel
    spec:
      containers:
        - name: sentinel
          image: redis:7.2
          command: ["redis-sentinel"]
          args:
            - "/etc/redis/sentinel.conf"
          volumeMounts:
            - name: config
              mountPath: /etc/redis
      volumes:
        - name: config
          configMap:
            name: sentinel-config
```

### Redis Memory Critical Rule
Kubernetes memory limit **must be higher** than `maxmemory` to account for fragmentation, overhead, and sidecar exporter. If limit equals `maxmemory`, Redis gets OOM-killed during memory fragmentation spikes.

## 9. Prometheus + Thanos Monitoring Stack

### Scenario
A Prometheus monitoring stack with Thanos sidecar for long-term retention. Prometheus runs as a StatefulSet (required for TSDB persistence), Thanos sidecar uploads blocks to object storage.

### Architecture

```
                    ┌─────────────────────────────┐
                    │      Thanos Query            │
                    │  (global query layer)        │
                    └──────┬──────────────┬───────┘
                           │              │
              ┌────────────┘              └────────────┐
              ▼                                        ▼
    ┌──────────────────┐                    ┌──────────────────┐
    │  Prometheus-0     │                    │  Prometheus-1     │
    │  ┌────────────┐   │                    │  ┌────────────┐   │
    │  │ Thanos     │   │                    │  │ Thanos     │   │
    │  │ Sidecar    │───┼──► S3/GCS ────────┼──┤ Sidecar    │   │
    │  └────────────┘   │                    │  └────────────┘   │
    │  ┌────────────┐   │                    │  ┌────────────┐   │
    │  │ TSDB PVC   │   │                    │  │ TSDB PVC   │   │
    │  └────────────┘   │                    │  └────────────┘   │
    └──────────────────┘                    └──────────────────┘
    externalLabels:                          externalLabels:
      cluster: prod-1                          cluster: prod-2
      replica: prometheus-0                    replica: prometheus-1
```

### Implementation

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: prometheus
spec:
  serviceName: prometheus-svc
  replicas: 2
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
        - name: prometheus
          image: prom/prometheus:v2.53
          args:
            - "--storage.tsdb.retention.time=15d"
            - "--storage.tsdb.path=/prometheus"
            - "--web.enable-lifecycle"
          ports:
            - containerPort: 9090
          volumeMounts:
            - name: tsdb
              mountPath: /prometheus
            - name: config
              mountPath: /etc/prometheus
        - name: thanos-sidecar
          image: quay.io/thanos/thanos:v0.34
          args:
            - "sidecar"
            - "--tsdb.path=/prometheus"
            - "--objstore.config-file=/etc/thanos/objstore.yml"
            - "--prometheus.url=http://localhost:9090"
          env:
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
          volumeMounts:
            - name: tsdb
              mountPath: /prometheus
            - name: thanos-config
              mountPath: /etc/thanos
      volumes:
        - name: config
          configMap:
            name: prometheus-config
        - name: thanos-config
          secret:
            secretName: thanos-objstore
  volumeClaimTemplates:
    - metadata:
        name: tsdb
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: ssd-storage
        resources:
          requests:
            storage: 200Gi
```

### Alertmanager as StatefulSet

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: alertmanager
spec:
  serviceName: alertmanager-svc
  replicas: 3
  selector:
    matchLabels:
      app: alertmanager
  template:
    spec:
      containers:
        - name: alertmanager
          image: prom/alertmanager:v0.27
          args:
            - "--config.file=/etc/alertmanager/alertmanager.yml"
            - "--cluster.listen-address=0.0.0.0:9094"
            - "--cluster.peer=alertmanager-0.alertmanager-svc:9094"
            - "--cluster.peer=alertmanager-1.alertmanager-svc:9094"
            - "--cluster.peer=alertmanager-2.alertmanager-svc:9094"
          ports:
            - containerPort: 9093
            - containerPort: 9094
          volumeMounts:
            - name: data
              mountPath: /var/lib/alertmanager
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 10Gi
```

### Prometheus Scaling Options

| Architecture | Max Series | Latency (p95) | Ops Complexity |
|---|---|---|---|
| Single Prometheus | ~500k | <1s | Low |
| Federation | 1M+ | 2–5s | Medium |
| Thanos + Sidecar | 5M+ | 1–3s | High |
| Grafana Mimir | 10M+ | 0.5–2s | Very High |

## 10. Distributed ML Training (PyTorch + Kubeflow)

### Scenario
A 4-node distributed PyTorch training job using Kubeflow Training Operator v2 (TrainJob API, GA July 2025). Each GPU node has a stable identity mapped to rank ordinal.

### Implementation

```yaml
apiVersion: trainer.kubeflow.org/v1alpha1
kind: TrainJob
metadata:
  name: llama-finetune
spec:
  runtimeRef:
    kind: ClusterTrainingRuntime
    name: torch-distributed
  trainer:
    numNodes: 4
    resourcesPerNode:
      requests:
        nvidia.com/gpu: 4
        memory: 64Gi
        cpu: 16
      limits:
        nvidia.com/gpu: 4
        memory: 128Gi
        cpu: 32
  datasetConfig:
    storage: 500Gi
    storageClassName: nfs-csi
```

### StatefulSet vs Job for ML

| Aspect | StatefulSet | Job / JobSet |
|--------|-------------|--------------|
| Identity | Stable per-pod ordinal | Ephemeral |
| Restart | Always restarts | Configurable (`backoffLimit`) |
| Parallelism | Ordered or parallel | Parallel or work queue |
| Use case | Training infrastructure, parameter servers | Ephemeral training runs, hyperparameter sweeps |
| GPU attach | Works | Works |
| Distributed training | Rank = ordinal — stable identity | Rank assigned dynamically |

For **distributed training** (PyTorch DDP, DeepSpeed, Horovod), StatefulSet is preferred because rank identity must be stable. For **single-node training** or sweeps, `Job` is more appropriate.

### NCCL Best Practices

- Stable network identity is critical for NCCL all-reduce — StatefulSet guarantees this
- Use `hostNetwork: true` for NCCL if performance-critical (bypasses CNI overhead)
- Ensure `CAP_SYS_NICE` and `CAP_SYS_RAWIO` for GPUDirect RDMA
- Set `ulimit memlock: unlimited` for large model training
- Use node pools with homogeneous GPU types (e.g., all A100-80GB) to avoid stragglers

## 11. etcd Cluster for Kubernetes Control Plane

### Scenario
A 3-node etcd cluster using StatefulSet for stable identity. Each node gets a predictable DNS name used for Raft peer communication.

### Key Specifications

| Property | Value |
|----------|-------|
| Replicas | 3 (odd number for quorum) |
| Quorum | 2 (can survive 1 node failure) |
| Storage | NVMe SSD, <1ms fsync latency |
| Network RTT | <50ms between members |
| Max DB size | Several GB (etcd is for metadata, not user data) |

### Implementation

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: etcd
spec:
  serviceName: etcd-svc
  replicas: 3
  selector:
    matchLabels:
      app: etcd
  template:
    spec:
      containers:
        - name: etcd
          image: gcr.io/etcd-development/etcd:v3.5
          env:
            - name: ETCD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: ETCD_INITIAL_CLUSTER
              value: "etcd-0=http://etcd-0.etcd-svc:2380,etcd-1=http://etcd-1.etcd-svc:2380,etcd-2=http://etcd-2.etcd-svc:2380"
            - name: ETCD_INITIAL_ADVERTISE_PEER_URLS
              value: "http://$(HOSTNAME).etcd-svc:2380"
            - name: ETCD_ADVERTISE_CLIENT_URLS
              value: "http://$(HOSTNAME).etcd-svc:2379"
          ports:
            - containerPort: 2379  # client
            - containerPort: 2380  # peer
          volumeMounts:
            - name: data
              mountPath: /var/lib/etcd
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: nvme-storage
        resources:
          requests:
            storage: 10Gi
```

### etcd Performance Benchmarks (v3.7)

| Scenario | Read QPS | Latency |
|----------|----------|---------|
| 1 client, serializable | 2,909 | 0.3ms |
| 1 client, linearizable | 1,353 | 0.7ms |
| 1,000 clients, serializable | 185,758 | 2.2ms |
| 1,000 clients, linearizable | 141,578 | 5.5ms |

## 12. GitOps for StatefulSets (ArgoCD + Helm)

### ArgoCD Best Practices for Stateful Workloads

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: postgres
spec:
  destination:
    namespace: db
  source:
    repoURL: https://github.com/myorg/gitops
    path: charts/postgres
  syncPolicy:
    automated:
      prune: false          # NEVER auto-prune StatefulSets
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - PrunePropagationPolicy=orphan
      - RespectIgnoreDifferences=true
```

**Critical rules:**
1. **`prune: false`** — accidental StatefulSet deletion = data loss
2. **`PrunePropagationPolicy=orphan`** — if pruning occurs, orphan PVCs (don't delete them)
3. **PVCs are NOT managed by ArgoCD** — they're created by the StatefulSet controller. ArgoCD sees them as "out of sync" by default. Use `RespectIgnoreDifferences=true`
4. **Helm chart must expose**: `persistence.size`, `persistence.storageClass`, `podManagementPolicy`, `updateStrategy.rollingUpdate.partition`

### App-of-Apps Pattern

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: infra-root
spec:
  source:
    path: apps
    repoURL: https://github.com/myorg/gitops
  destination:
    namespace: argocd
  project: default
  syncPolicy:
    automated:
      prune: false
---
# apps/postgres/app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: postgres
spec:
  source:
    path: apps/postgres
    repoURL: https://github.com/myorg/gitops
  destination:
    namespace: db
  syncPolicy:
    automated:
      prune: false
---
# apps/kafka/app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: kafka
spec:
  source:
    path: apps/kafka
    repoURL: https://github.com/myorg/gitops
  destination:
    namespace: messaging
```

## 13. Service Mesh with StatefulSets (Istio)

### Istio + StatefulSet Considerations

| Aspect | Implication |
|--------|-------------|
| **Same SA for all ordinals** | All pods share identity per ServiceAccount — can't distinguish in mTLS policy by pod name |
| **mTLS to specific pod** | Works via DNS name, but identity is SA-based |
| **`holdApplicationUntilProxyStarts: true`** | Critical — ensures app doesn't start before sidecar proxy is ready |
| **Headless service discovery** | Istio treats headless services differently — creates individual endpoints per pod (no ClusterIP load balancing) |
| **DNS proxy** | Envoy sidecar can proxy DNS for headless services, returning all pod IPs |
| **`idleTimeout` on sidecar** | Critical for long-lived connections (DB pools, message consumers) — defaults may close idle connections prematurely |
| **Stale endpoint issue** | In large clusters, stale pod IPs can accumulate in proxy endpoint lists causing 503s. Istio 1.19+ improves endpoint cleanup |

### Authorization Policy Per Ordinal

```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: db-access
spec:
  selector:
    matchLabels:
      statefulset.kubernetes.io/pod-name: postgres-0
  rules:
    - from:
        - source:
            principals: ["cluster.local/ns/app/sa/app-sa"]
      to:
        - operation:
            methods: ["POST", "PUT", "DELETE"]
```

### NetworkPolicy with Ordinals

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: restrict-db-access
spec:
  podSelector:
    matchLabels:
      statefulset.kubernetes.io/pod-name: postgres-0
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: api-server
      ports:
        - port: 5432
```

## Key Patterns

1. **Quorum-based systems** (etcd, ZooKeeper, Consul): always run an **odd number** of replicas (3 or 5)
2. **Primary-replica** (PostgreSQL, MySQL): `pod-0` is typically the primary
3. **Gossip-based** (Cassandra, Elasticsearch): all nodes are equal, discovery via seed list
4. **Log-based** (Kafka): brokers identify by ID matching the ordinal index
5. **Leader election** (RabbitMQ, MongoDB): nodes elect a leader internally
6. **Sidecar pattern** (Prometheus + Thanos): sidecar container handles block upload, decoupling storage from collection
7. **Operator-managed** (Kafka, PG, ES): operators provide domain-specific lifecycle beyond what raw StatefulSets offer
