# Kubernetes — DevOps Cheatsheet

## Core Resources

### Pod
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
  labels:
    app: myapp
spec:
  containers:
    - name: app
      image: nginx:alpine
      ports:
        - containerPort: 80
      resources:
        requests: { cpu: 100m, memory: 128Mi }
        limits:   { cpu: 500m, memory: 256Mi }
      livenessProbe:  { httpGet: { path: /, port: 80 } }
      readinessProbe: { httpGet: { path: /, port: 80 } }
      env:
        - name: KEY
          value: val
        - name: SECRET
          valueFrom:
            secretKeyRef: { name: my-secret, key: pass }
      volumeMounts:
        - mountPath: /data
          name: data
  volumes:
    - name: data
      persistentVolumeClaim: { claimName: my-pvc }
  restartPolicy: Always
  nodeSelector:
    disktype: ssd
  tolerations:
    - key: "key1", operator: "Equal", value: "val1", effect: "NoSchedule"
  affinity:
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          podAffinityTerm:
            labelSelector: { matchLabels: { app: myapp } }
            topologyKey: kubernetes.io/hostname
```

### Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-deploy
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate: { maxUnavailable: 1, maxSurge: 1 }
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
          image: myapp:1.2.3
```

### Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-svc
spec:
  type: ClusterIP  # NodePort | LoadBalancer | ExternalName
  selector:
    app: myapp
  ports:
    - port: 80
      targetPort: 8080
      nodePort: 30080   # only for NodePort
```

### Ingress
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - host: myapp.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-svc
                port:
                  number: 80
  tls:
    - hosts: [myapp.example.com]
      secretName: my-tls
```

### ConfigMap & Secret
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config
data:
  app.properties: |
    key=value
---
apiVersion: v1
kind: Secret
type: Opaque  # kubernetes.io/tls | kubernetes.io/dockerconfigjson
metadata:
  name: my-secret
stringData:
  password: supersecret
```

### PersistentVolumeClaim
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes: [ReadWriteOnce]  # ReadWriteMany | ReadOnlyMany
  resources:
    requests:
      storage: 10Gi
  storageClassName: standard
```

### Namespace
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: my-ns
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: my-quota
  namespace: my-ns
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
    pods: "20"
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-other-ns
  namespace: my-ns
spec:
  podSelector: {}
  policyTypes: [Ingress]
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: my-ns
```

### HPA
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: my-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-deploy
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```

### ServiceAccount & RBAC
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-sa
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
rules:
  - apiGroups: [""]
    resources: [pods, pods/log]
    verbs: [get, list, watch]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
subjects:
  - kind: ServiceAccount
    name: my-sa
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

### Job / CronJob
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: my-job
spec:
  backoffLimit: 3
  template:
    spec:
      containers:
        - name: job
          image: busybox
          command: ["echo", "done"]
      restartPolicy: Never
---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: my-cron
spec:
  schedule: "*/5 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: cron
              image: busybox
              command: ["echo", "tick"]
          restartPolicy: OnFailure
```

### StatefulSet
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: my-stateful
spec:
  serviceName: my-svc
  replicas: 3
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
          image: postgres:16
          volumeMounts:
            - name: data
              mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: [ReadWriteOnce]
        resources:
          requests:
            storage: 10Gi
```

### DaemonSet
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
      tolerations:
        - operator: Exists
      containers:
        - name: fluentd
          image: fluentd:latest
```

## kubectl Commands

```bash
# Get
k get pods -n ns -o wide
k get deploy,svc -l app=myapp
k describe pod my-pod

# Create / Apply
k apply -f manifest.yaml
k create deployment my-dep --image=nginx
k create configmap my-cfg --from-file=config.properties
k create secret generic my-sec --from-literal=key=val
k run tmp --image=busybox -it --rm -- sh

# Delete
k delete pod my-pod
k delete -f manifest.yaml

# Debug
k logs -f deployment/my-deploy
k logs --since=5m -l app=myapp
k exec -it my-pod -- sh
k port-forward pod/my-pod 8080:80
k cp my-pod:/tmp/file ./local

# Rollout
k rollout status deployment/my-deploy
k rollout history deployment/my-deploy
k rollout undo deployment/my-deploy --to-revision=2

# Scale / Autoscale
k scale deployment/my-deploy --replicas=5
k autoscale deployment/my-deploy --min=2 --max=10 --cpu-percent=70

# Context
k config current-context
k config use-context prod
k config set-context --current --namespace=prod
k config view

# Nodes
k top node
k top pod
k cordon node-1
k drain node-1 --ignore-daemonsets --delete-emptydir-data
k uncordon node-1

# Troubleshoot
k get events --sort-by='.lastTimestamp'
k describe node worker-1 | grep -A5 Conditions
k api-resources
k explain deployment.spec

# JSON / YAML output
k get pod my-pod -o json
k get pod my-pod -o yaml
k get pods -o jsonpath='{.items[*].metadata.name}'
k get pods --field-selector=status.phase!=Running
```

## Helm

```bash
helm create my-chart
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm search repo nginx

helm install my-release bitnami/nginx -f values.yaml
helm upgrade my-release bitnami/nginx -f values.yaml --set image.tag=2.0
helm rollback my-release 1
helm uninstall my-release
helm list
helm get values my-release
helm template my-release .    # render locally
```

### Chart Structure

```
my-chart/
├── Chart.yaml        # name, version, description
├── values.yaml       # default values
├── charts/           # subcharts
└── templates/
    ├── _helpers.tpl  # named templates
    ├── deployment.yaml
    ├── service.yaml
    └── NOTES.txt
```

### Helm Template Functions

```yaml
{{ .Release.Name }}
{{ .Values.replicaCount | default 3 }}
{{ .Chart.Name }}-{{ .Values.env }}
{{- include "my-chart.labels" . | nindent 4 }}
{{- if .Values.ingress.enabled }}
{{- range .Values.ports }}
  - port: {{ . }}
{{- end }}
```

## Key Concepts

| Concept | Summary |
|---------|---------|
| **Pod** | smallest unit, ephemeral |
| **Deployment** | stateless workloads, rolling updates |
| **StatefulSet** | stateful, stable network ID, ordered |
| **DaemonSet** | one pod per node (logging, monitoring) |
| **Job** | run-to-completion |
| **CronJob** | scheduled jobs |
| **Service** | stable network endpoint |
| **Ingress** | L7 routing (host/path) |
| **ConfigMap/Secret** | config injection |
| **PV/PVC** | persistent storage |
| **HPA** | auto-scale based on CPU/mem/custom |
| **NetworkPolicy** | pod-level firewall |
| **RBAC** | access control |
| **Namespace** | isolation boundary |
| **ResourceQuota/LimitRange** | resource governance |
| **Node** | worker machine |
| **Taint/Toleration** | scheduling restrictions |
| **Affinity** | scheduling preferences |
| **Operator** | app-specific controller pattern |
