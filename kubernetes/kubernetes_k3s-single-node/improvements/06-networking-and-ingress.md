# Networking & Ingress Improvements

## Current State

| Service | Type | Cluster IP | External IP | Port |
|---|---|---|---|---|
| traefik | LoadBalancer | 10.43.106.102 | 192.168.64.23 | 80:30982, 443:32412 |
| floci | LoadBalancer | 10.43.7.85 | 192.168.64.23 | 4566:31363 |
| docker-registry | LoadBalancer | 10.43.95.70 | 192.168.64.23 | 5000:31430 |
| wordpress (default) | ClusterIP | 10.43.41.38 | none | 80 |
| wordpress (demo) | ClusterIP | 10.43.100.24 | none | 80 |
| mariadb (default) | ClusterIP | 10.43.164.125 | none | 3306 |
| mariadb (demo) | ClusterIP | 10.43.199.54 | none | 3306 |

## Issues & Improvements

### 1. No Ingress Resources

**Problem**: Traefik (ingress controller) is running but no `Ingress` resources are configured. Services like WordPress, Registry, Regui are only accessible via direct LoadBalancer IP + port, or ClusterIP (internal only).

**Fix**: Use Ingress with host-based routing:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: wordpress-ingress
  namespace: demo
spec:
  ingressClassName: traefik
  rules:
  - host: wordpress.example.com
    http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: wordpress
            port:
              number: 80
```

### 2. Multiple LoadBalancer Services on a Single Node

**Problem**: floci and docker-registry each get their own `LoadBalancer` service, mapping to separate NodePorts. This is not efficient — each LoadBalancer allocates a NodePort and adds svclb DaemonSet pods.

**Fix**: Expose everything through a single Traefik LoadBalancer with Ingress rules. Convert floci and docker-registry to ClusterIP services.

### 3. No TLS on Ingress

**Problem**: TLS secrets exist (`registry-tls`, `demo-tls`) but are not used by any Ingress.

**Fix**: Configure TLS termination at the Ingress:
```yaml
spec:
  tls:
  - hosts:
    - registry.example.com
    secretName: registry-tls
  rules:
  - host: registry.example.com
    http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: docker-registry
            port:
              number: 5000
```

### 4. Floci Exposed Directly Without Auth

**Problem**: Floci (port 4566 — likely a localstack-compatible service) is exposed via LoadBalancer with no authentication.

**Fix**: Place behind Traefik with middleware:
```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: floci-basicauth
spec:
  basicAuth:
    secret: floci-auth-secret
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    traefik.ingress.kubernetes.io/router.middlewares: default-floci-basicauth@kubernetescrd
spec:
  ...
```

### 5. No Rate Limiting / DDoS Protection

**Add Traefik middleware for rate limiting**:
```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: rate-limit
spec:
  rateLimit:
    average: 100
    burst: 50
```
