# Setup Fix Notes

## Initial Cluster State (2026-05-12)

### Nodes
| Name         | Status    | Role          |
|--------------|-----------|---------------|
| k8s-master   | NotReady  | control-plane |
| k8s-worker   | NotReady  | <none>        |

### kube-system Pods
| Pod                          | Status  | Node         |
|------------------------------|---------|--------------|
| coredns-* (x2)               | Pending | -            |
| etcd-k8s-master              | Running | k8s-master   |
| kube-apiserver-k8s-master    | Running | k8s-master   |
| kube-controller-manager-k8s-master | Running | k8s-master |
| kube-proxy-* (x2)            | Running | both nodes   |
| kube-scheduler-k8s-master    | Running | k8s-master   |

### Observation
Both nodes NotReady + CoreDNS Pending — CNI plugin was missing at first but cluster self-healed after provisioning completed (Flannel was installed).

## Changes Made

### 1. hello-world.yaml — Full rewrite
- **Before**: Used `hashicorp/http-echo` on port 5678, HTTP only, no SSL.
- **After**: Uses `nginx:alpine` with:
  - Self-signed TLS cert (`CN=hello-world.local`) valid for 1 year
  - TLS Secret (`hello-world-tls`) mounted into nginx
  - ConfigMap (`hello-world-nginx`) with custom nginx config serving HTTPS on port 443
  - NodePort service exposing **443:30443**
  - 2 replicas

### 2. TLS Secret created
- `hello-world-tls` — generated via OpenSSL, stored as `kubernetes.io/tls` secret
- Base64 cert/key also embedded in `hello-world.yaml` for portability.

## How to Test
```bash
curl -sk https://192.168.64.18:30443
# → Hello World from Kubernetes!
```
