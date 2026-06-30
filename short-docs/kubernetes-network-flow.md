# Kubernetes Network Flow — Step by Step

## Step 0: Pod Basics

A Pod is the smallest deployable unit — one or more containers sharing a network stack (IP, port space).

```mermaid
flowchart LR
    subgraph "Pod"
        C1["Container A\nport 8080"]
        C2["Container B\nport 3000"]
    end
    C1 <==>|"localhost"| C2
```

Containers inside the same Pod communicate via `localhost`.

## Step 1: Pod-to-Pod (Same Node)

Each Pod gets a unique cluster IP. On the same node, traffic flows through the CNI bridge.

```mermaid
flowchart LR
    subgraph "Node"
        subgraph "Pod A"
            A["app\n10.1.0.1:8080"]
        end
        subgraph "Pod B"
            B["db\n10.1.0.2:5432"]
        end
        A -- "10.1.0.2:5432\nvia CNI bridge" --> B
    end
```

## Step 2: Pod-to-Pod (Different Nodes)

Across nodes, traffic goes through the CNI overlay network (e.g. Calico, Flannel, Cilium).

```mermaid
flowchart LR
    subgraph "Node 1"
        A["Pod A\n10.1.0.1:8080"]
    end
    subgraph "Node 2"
        B["Pod B\n10.2.0.2:5432"]
    end
    A == "overlay network\n(vxlan/geneve/ipip)" ==> B
```

**Problem**: Pod IPs are ephemeral. If Pod A dies and recreates on Node 2, Pod B's hardcoded IP breaks.

## Step 3: Service (ClusterIP) — Stable Internal Name

A Service gives a stable virtual IP and DNS name, load-balancing across Pods.

```mermaid
flowchart LR
    subgraph "Cluster"
        S["Service: 'db-svc'\nClusterIP: 10.3.0.10\nDNS: db-svc.ns.svc.cluster.local"]
        subgraph "Node 1"
            A["Pod A\ndb-v1\n10.1.0.1:5432"]
        end
        subgraph "Node 2"
            B["Pod B\ndb-v1\n10.2.0.2:5432"]
        end
        C["Consumer Pod"]
        C -- "db-svc:5432" --> S
        S -- "kube-proxy\niptables/ipvs" --> A
        S -- "kube-proxy\niptables/ipvs" --> B
    end
```

### What happens when you `curl db-svc:5432`:

```mermaid
sequenceDiagram
    participant C as Consumer Pod
    participant DNS as CoreDNS
    participant S as Service (ClusterIP)
    participant P1 as Pod A (Endpoint 1)
    participant P2 as Pod B (Endpoint 2)
    C->>DNS: db-svc.ns.svc.cluster.local?
    DNS-->>C: 10.3.0.10
    C->>S: 10.3.0.10:5432
    Note over S: kube-proxy intercepts via iptables/ipvs
    S->>P1: balanced to 10.1.0.1:5432
    P1-->>C: response
```

```yaml
apiVersion: v1
kind: Service
metadata:
  name: db-svc
spec:
  type: ClusterIP
  selector:
    app: db
  ports:
    - port: 5432
      targetPort: 5432
```

**Reachability**: cluster-internal only. No external access.

## Step 4: NodePort — Open a Port on Every Node

NodePort maps a high port (30000-32767) on every node to the Service.

```mermaid
flowchart TB
    subgraph "Internet"
        DEV["Developer laptop\nor external tool"]
    end
    subgraph "Cluster"
        S["Service: 'db-svc'\nClusterIP: 10.3.0.10\ntype: NodePort"]
        subgraph "Node 1 (IP: 54.1.1.1)"
            NP1[":30432"]
            A["Pod A\n10.1.0.1:5432"]
        end
        subgraph "Node 2 (IP: 54.1.1.2)"
            NP2[":30432"]
            B["Pod B\n10.2.0.2:5432"]
        end
    end
    DEV -- "54.1.1.1:30432" --> NP1
    DEV -- "54.1.1.2:30432" --> NP2
    NP1 --> S --> A
    NP2 --> S --> B
```

```yaml
apiVersion: v1
kind: Service
metadata:
  name: db-svc
spec:
  type: NodePort
  selector:
    app: db
  ports:
    - port: 5432
      targetPort: 5432
      nodePort: 30432
```

**Problem**: You must know a node IP and manage firewall rules. No load-balancing across nodes. Node port range is limited.

## Step 5: LoadBalancer — Cloud LB in Front

Cloud providers automatically provision a load balancer that forwards to NodePort on all nodes.

```mermaid
flowchart TB
    subgraph "Internet"
        CLIENT["Client"]
    end
    subgraph "Cloud"
        LB["Cloud Load Balancer\n(AWS: ELB/NLB, GCP: TCP LB)\nListen: 5432"]
    end
    subgraph "VPC"
        subgraph "Node 1"
            NP1[":30432"]
            A["Pod A\n10.1.0.1:5432"]
        end
        subgraph "Node 2"
            NP2[":30432"]
            B["Pod B\n10.2.0.2:5432"]
        end
    end
    CLIENT -- "lb.example.com:5432" --> LB
    LB -- "health check onward" --> NP1
    LB -- "health check onward" --> NP2
    NP1 --> A
    NP2 --> B
```

```yaml
apiVersion: v1
kind: Service
metadata:
  name: db-svc
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: external
    service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
spec:
  type: LoadBalancer
  selector:
    app: db
  ports:
    - port: 5432
      targetPort: 5432
```

**Flow**: `Client → LB DNS → Cloud LB → :NodePort on any healthy node → Pod`.

**Problem**: One LB per service = expensive. No L7 routing (host/path/TLS).

## Step 6: Ingress — L7 Routing to Multiple Services

One Ingress Controller handles TLS termination, path-based routing, and host-based routing for many Services.

```mermaid
flowchart TB
    C["Client"]
    DNS["app.example.com to LB IP"]
    LB["Cloud LB\nport 443"]
    IC["Ingress Controller\n(nginx/traefik/ALB Ingress)\nNodePort 30080"]
    S1["Service: web-svc\nClusterIP 10.3.0.20"]
    S2["Service: api-svc\nClusterIP 10.3.0.30"]
    S3["Service: static-svc\nClusterIP 10.3.0.40"]
    P1["Web Pods\n10.1.0.x:8080"]
    P2["API Pods\n10.1.1.x:8080"]
    P3["Static Pods\n10.1.2.x:80"]

    C -- "DNS lookup" --> DNS
    DNS -- "resolve" --> LB
    LB -- "port 443 to 30080" --> IC
    IC -- "path / to web-svc" --> S1
    IC -- "path /api to api-svc" --> S2
    IC -- "path /static to static-svc" --> S3
    S1 --> P1
    S2 --> P2
    S3 --> P3
```

### Ingress routing decision:

```mermaid
flowchart TB
    REQ["Request\nHost: app.example.com\nPath: /api/users"]
    REQ --> IC["Ingress Controller"]
    IC --> RULE{"Match rules"}
    RULE -- "host: app.example.com path /api" --> API_SVC["Service: api-svc\nClusterIP 10.3.0.30:80"]
    RULE -- "host: app.example.com path /" --> WEB_SVC["Service: web-svc\nClusterIP 10.3.0.20:80"]
    RULE -- "host: api.example.com" --> API2["Service: external-api\nExternalName"]
    API_SVC --> API_POD["Pod A: 10.1.1.1:8080"]
    API_SVC --> API_POD2["Pod B: 10.1.1.2:8080"]
```

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - app.example.com
      secretName: app-tls
  rules:
    - host: app.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web-svc
                port:
                  number: 80
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: api-svc
                port:
                  number: 80
    - host: api.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: external-api
                port:
                  number: 80
```

## Step 7: TLS Termination Options

```mermaid
sequenceDiagram
    participant C as Client
    participant LB as Cloud LB
    participant IC as Ingress Controller
    participant SVC as Service
    participant POD as Pod

    Note over C,POD: Option A: TLS at LB (common with ALB)
    C->>LB: TLS (SNI: app.example.com)
    Note over LB: Decrypt (ACM cert)
    LB->>IC: HTTP (plain)
    IC->>SVC: HTTP
    SVC->>POD: HTTP

    Note over C,POD: Option B: TLS at Ingress (common with nginx)
    C->>LB: TLS passthrough or LB with cert
    LB->>IC: TLS or HTTP
    Note over IC: Decrypt (k8s Secret)
    IC->>SVC: HTTP
    SVC->>POD: HTTP

    Note over C,POD: Option C: Re-encrypt (end-to-end TLS)
    C->>LB: TLS
    LB->>IC: TLS (decrypt at LB, re-encrypt to IC)
    Note over IC: Decrypt (secret), then encrypt again
    IC->>SVC: TLS (optional mTLS with Pod)
    SVC->>POD: TLS (mTLS)
```

## Step 8: NetworkPolicies — Pod-Level Firewall

Without policies: all Pods can talk to all Pods (flat network). NetworkPolicies restrict that.

### Default: All Allow
```mermaid
flowchart LR
    P1["Pod A\napp: web"]
    P2["Pod B\napp: db"]
    P3["Pod C\napp: cache"]
    P1 --> P2
    P1 --> P3
    P2 --> P3
    P3 --> P2
```

### With Default Deny + Allow Rules
```mermaid
flowchart TB
    subgraph "Namespace: app"
        WEB["Pod: web\napp=web"]
    end
    subgraph "Namespace: db"
        DB1["Pod: db-primary\napp=db,role=primary"]
        DB2["Pod: db-readonly\napp=db,role=readonly"]
    end
    subgraph "Namespace: monitoring"
        PROM["Pod: prometheus\napp=prometheus"]
    end
    subgraph "Namespace: ingress"
        IC["Pod: ingress-nginx\napp.kubernetes.io/name=ingress-nginx"]
    end

    IC -- "NetworkPolicy: allow-ingress\nport 8080" --> WEB
    WEB -- "NetworkPolicy: allow-web-to-db\nport 5432" --> DB1
    WEB -.->|"DENY (no policy)"| DB2
    PROM -- "NetworkPolicy: allow-metrics\nport 9090" --> WEB
```

```yaml
# Default deny all ingress
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: app
spec:
  podSelector: {}
  policyTypes:
    - Ingress
---
# Allow from ingress controller
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-ingress
  namespace: app
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: ingress-nginx
          podSelector:
            matchLabels:
              app.kubernetes.io/name: ingress-nginx
      ports:
        - port: 8080
---
# Allow web → db-primary only
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-web-to-db
  namespace: db
spec:
  podSelector:
    matchLabels:
      role: primary
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: app
          podSelector:
            matchLabels:
              app: web
      ports:
        - port: 5432
---
# Allow prometheus → web metrics
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-metrics
  namespace: app
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: monitoring
          podSelector:
            matchLabels:
              app: prometheus
      ports:
        - port: 9090
```

## Step 9: Full Production Flow

```mermaid
flowchart TB
    subgraph "Internet"
        U["User\nBrowser/curl"]
    end
    subgraph "DNS"
        R["Route53\napp.example.com to LB"]
    end
    subgraph "AWS"
        WAF["WAF\nrate-limit\nblock IPs"]
        LB["ALB\nListener: 443\nTLS (ACM cert)\nSG: allow443/0"]
    end
    subgraph "EKS Cluster"
        subgraph "ingress-nginx NS"
            IC["Ingress Controller\nService: type=NodePort\n:30080"]
        end
        subgraph "app NS"
            SVC["Service: app-svc\nClusterIP: 10.3.0.10:80"]
            P1["Pod: app-v1\n10.1.0.1:8080"]
            P2["Pod: app-v1\n10.1.1.2:8080"]
        end
        subgraph "db NS"
            NP["NetworkPolicy\nallow-app:5432"]
            DB["Pod: postgres\n10.1.2.3:5432"]
        end
        subgraph "monitoring NS"
            PROM["Prometheus"]
        end
    end

    U --> R
    R --> LB
    LB --> WAF
    WAF --> IC
    IC -- "Host: app.example.com\nPath: /" --> SVC
    SVC --> P1
    SVC --> P2
    P1 -- "NP allow:5432" --> DB
    P2 -- "NP allow:5432" --> DB
    PROM -- "NP allow:9090" --> P1
    PROM -- "NP allow:9090" --> P2
```

## Step 10: Service Type Decision Tree

```mermaid
flowchart TD
    START["I need to expose my app"] --> Q1{Needs external\naccess?}
    Q1 -- "No\ninternal only" --> Q1b{Multiple backends\nor stable DNS?}
    Q1b -- "Yes" --> CLUSTERIP["ClusterIP\nsvc:port to pod:targetPort\nstable DNS name"]
    Q1b -- "No" --> DIRECT["Direct Pod IP\n(ephemeral, not recommended)"]
    Q1 -- "Yes" --> Q2{Single or\nmultiple services?}
    Q2 -- "Single" --> Q3{Need load\nbalancing?}
    Q3 -- "No\nsimple testing" --> NODEPORT["NodePort\nnodeIP:3xxxx\nmanual LB required"]
    Q3 -- "Yes" --> LOADB["LoadBalancer\nCloud LB per service\nL4 only (port-based)"]
    Q2 -- "Multiple\nmicroservices" --> INGRESS["Ingress + ClusterIP\nSingle LB shared\nL7 routing (host/path)\nTLS termination"]
    CLUSTERIP --> DONE
    NODEPORT --> DONE
    LOADB --> DONE
    INGRESS --> DONE
    DONE["Done"]
```

## Full Comparison Table

| Step | Resource | External Access | LB | L7 | TLS | Use Case |
|------|----------|:---------------:|:--:|:--:|:---:|----------|
| 0 | Pod | ✗ | ✗ | ✗ | ✗ | Container runtime unit |
| 1-2 | Pod IP | ✗ | ✗ | ✗ | ✗ | Internal only (ephemeral) |
| 3 | ClusterIP | ✗ | ✔ | ✗ | ✗ | Microservice-to-microservice |
| 4 | NodePort | ✔ (nodeIP:port) | ✗ | ✗ | ✗ | Debug, bare-metal |
| 5 | LoadBalancer | ✔ (LB DNS) | ✔ | ✗ | ✔ (at LB) | Single service, simple |
| 6+ | Ingress | ✔ (hostname) | ✔ | ✔ | ✔ (IC) | Multi-service, routing needed |
| 8 | NetworkPolicy | controls access | ✗ | ✗ | ✗ | Pod-level firewall |
