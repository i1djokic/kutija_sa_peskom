# Kubernetes StatefulSets — Deep Dive Guide

A comprehensive guide to understanding, deploying, and managing **StatefulSets** in Kubernetes.

## What's Inside

| File | Description |
|------|-------------|
| [`01-comparison-with-other-workloads.md`](./01-comparison-with-other-workloads.md) | Full comparison matrix, StatefulSet vs Deployment (with PVCs), vs DaemonSet (fencing, taints, local storage), vs Job/CronJob (backup & migration patterns), vs operators (when to use Strimzi/CNPG/ECK), HPA & VPA with StatefulSets, PodDisruptionBudget deep-dive (quorum, unhealthy pod eviction), topology spread constraints, StatefulSets on spot/preemptible instances |
| [`02-real-life-examples.md`](./02-real-life-examples.md) | 13 complete real-world examples: PostgreSQL primary-replica, Kafka + ZooKeeper, Elasticsearch, MongoDB replica set, RabbitMQ cluster, Cassandra ring, etcd, Redis Sentinel HA, Prometheus + Thanos monitoring stack, Alertmanager mesh, distributed ML training (PyTorch + Kubeflow), blockchain nodes, GitOps with ArgoCD (app-of-apps, prune safeguards), Istio service mesh (mTLS, authorization policy, network policy with ordinals) |
| [`03-statefulsets-basics.md`](./03-statefulsets-basics.md) | Core concepts: stable identity, headless services & DNS (A/SRV records), ordered deployment, rolling updates (partition, canary, blue-green, OnDelete), start ordinal, ordinal-based application logic, scaling patterns (PDB, PVC retention, scale-to-zero), common pitfalls & anti-patterns |
| [`04-storage-and-data-sharing.md`](./04-storage-and-data-sharing.md) | Persistent storage with `volumeClaimTemplates`, sharing data between pods (RWX patterns), Longhorn operator (engine/replica architecture, V2 engine, snapshots, backups, RWX), Rook Ceph operator (RBD vs CephFS, CRUSH, mirroring), topology-aware provisioning (`WaitForFirstConsumer`), encryption at rest & in transit, cost optimization (thin provisioning, storage tiers, replica tradeoffs), storage migration, CSI cloning |

## Prerequisites

- Basic Kubernetes knowledge (Pods, Services, ConfigMaps)
- `kubectl` installed and configured
- A Kubernetes cluster (local: Minikube/Kind, or remote)

## Quick Start

```bash
# Apply a StatefulSet example
kubectl apply -f https://k8s.io/examples/application/web/web.yaml
```

## Why StatefulSets?

StatefulSets are the **only** Kubernetes workload resource that guarantees:

- **Stable, unique network identities** — each pod gets a predictable hostname (`pod-name-0`, `pod-name-1`, …)
- **Stable, persistent storage** — each pod gets its own PVC that persists across rescheduling
- **Ordered, graceful deployment and scaling** — pods are created/terminated one at a time in sequence
- **Ordered, graceful rolling updates** — updates roll out in reverse ordinal order (highest to lowest)

Use StatefulSets when your application needs **stable identity** or **stable storage** — databases, queues, and any stateful workload.
