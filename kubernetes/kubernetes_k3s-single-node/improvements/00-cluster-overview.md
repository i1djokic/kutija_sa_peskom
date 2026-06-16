# Cluster Overview

## Topology

| Property | Value |
|---|---|
| Node | k3s-server (control-plane) |
| OS | CentOS Stream 10 (Coughlan) |
| Architecture | arm64 (aarch64) |
| CPU | 2 vCPUs |
| Memory | 3.8 GiB |
| Kubernetes | v1.35.4+k3s1 |
| Container Runtime | containerd://2.2.3-k3s1 |
| Kernel | 6.12.0-226.el10.aarch64 |
| Network | Flannel VXLAN (10.42.0.0/24) |
| Service CIDR | 10.43.0.0/16 |
| Ingress Controller | Traefik (LoadBalancer on 192.168.64.23) |
| Storage | local-path-provisioner (WaitForFirstConsumer) |
| Certificates Auto-Managed | K3s built-in |
| Age | ~47 hours |

## Namespaces

| Namespace | Purpose |
|---|---|
| `default` | User workloads (floci, mariadb, wordpress) |
| `demo` | Demo WordPress + MariaDB |
| `registry` | Local Docker registry (docker-registry + regui) |
| `debug` | Debug/tooling namespace |
| `kube-system` | System components (coredns, traefik, metrics-server, local-path-provisioner) |
| `kube-node-lease` | Node lease heartbeats |
| `kube-public` | Public cluster info |

## Workloads

| Namespace | Workload | Type | Replicas | Image |
|---|---|---|---|---|
| default | floci | Deployment | 1 | floci/floci:latest |
| demo | mariadb | Deployment | 1 | mariadb:11 |
| demo | wordpress | Deployment | 1 | wordpress:latest |
| kube-system | coredns | Deployment | 1 | rancher/mirrored-coredns-coredns:1.14.2 |
| kube-system | local-path-provisioner | Deployment | 1 | rancher/local-path-provisioner |
| kube-system | metrics-server | Deployment | 1 | rancher/mirrored-metrics-server |
| kube-system | traefik | Deployment | 1 | traefik |
| registry | docker-registry | Deployment | 1 | registry:2 |
| registry | regui | Deployment | 1 | 127.0.0.1:5000/regui:v2 |
