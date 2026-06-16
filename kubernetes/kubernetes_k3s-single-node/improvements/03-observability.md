# Observability Improvements

## Current State

| Component | Status |
|---|---|
| metrics-server | Installed (readiness probe failing) |
| Pod Resource Metrics | Available (`kubectl top`) |
| Logging | No central log aggregation |
| Monitoring | No Prometheus/Grafana |
| Alerting | None |
| Tracing | None |
| Audit Logging | Not enabled (K3s default) |

## Improvements

### 1. Fix metrics-server

The readiness probe is failing (HTTP 500). Investigate and fix:
```bash
kubectl logs -n kube-system deployment/metrics-server
kubectl describe pod -n kube-system -l k8s-app=metrics-server
```

### 2. Install Prometheus Stack (kube-prometheus-stack)

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace
```

This provides:
- Prometheus for metrics collection
- Grafana for dashboards
- AlertManager for alerting
- Node/ Pod/ Kubelet dashboards out of the box

### 3. Centralized Logging

**Option A**: Loki + Promtail (lightweight, native with Grafana)
```bash
helm install loki grafana/loki --namespace=loki --create-namespace
helm install promtail grafana/promtail --namespace=loki
```

**Option B**: Elasticsearch + Filebeat + Kibana (heavier, more features)
```bash
helm install elasticsearch elastic/elasticsearch --namespace=logging
helm install filebeat elastic/filebeat --namespace=logging
helm install kibana elastic/kibana --namespace=logging
```

### 4. Enable Kubernetes Audit Logging

On K3s server, add to config:
```yaml
# /etc/rancher/k3s/config.yaml
kube-apiserver-arg:
  - audit-log-path=/var/lib/rancher/k3s/server/logs/audit.log
  - audit-policy-file=/var/lib/rancher/k3s/server/audit-policy.yaml
```

### 5. Install Dashboard (for visual management)

```bash
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard \
  --namespace kube-system
```

### 6. Alerts to Set Up

| Alert | Threshold | Channel |
|---|---|---|
| Node CPU > 80% | > 80% for 5m | Email / Slack |
| Node Memory > 80% | > 80% for 5m | Email / Slack |
| Pod CrashLoopBackOff | any | Email / Slack |
| Disk Pressure | any | Email / Slack |
| Certificate Expiry | < 30 days | Email / Slack |
