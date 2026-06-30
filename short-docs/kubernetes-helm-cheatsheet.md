# Helm — DevOps Cheatsheet

## Chart Structure

```
my-chart/
├── Chart.yaml                # metadata: name, version, description
├── values.yaml               # default values
├── values.schema.json        # JSON schema validation
├── charts/                   # subcharts (dependencies)
├── templates/
│   ├── _helpers.tpl          # named templates (reusable snippets)
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── hpa.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── serviceaccount.yaml
│   ├── pvc.yaml
│   ├── tests/
│   │   └── test-connection.yaml
│   └── NOTES.txt             # post-install message
└── crds/                     # CRDs (install before templates)
```

## Chart.yaml

```yaml
apiVersion: v2
name: myapp
description: A Helm chart for Kubernetes
type: application            # application | library
version: 0.1.0
appVersion: "1.16.0"
kubeVersion: ">=1.24.0"
keywords:
  - web
maintainers:
  - name: Alice
    email: alice@example.com
dependencies:
  - name: postgresql
    version: "~12.0"
    repository: https://charts.bitnami.com/bitnami
    condition: postgresql.enabled
    tags:
      - database
  - name: redis
    version: "~17.0"
    repository: oci://registry-1.docker.io/bitnamicharts
    alias: cache
icon: https://example.com/icon.png
```

## Chart Hooks

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: "{{ .Release.Name }}-migrate"
  annotations:
    "helm.sh/hook": pre-install,pre-upgrade
    "helm.sh/hook-weight": "-5"
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: migrate
          image: myapp:{{ .Values.image.tag }}
          command: ["./run-migrations"]
```

| Hook | When |
|------|------|
| `pre-install` | before install |
| `post-install` | after install |
| `pre-delete` | before delete |
| `post-delete` | after delete |
| `pre-upgrade` | before upgrade |
| `post-upgrade` | after upgrade |
| `pre-rollback` | before rollback |
| `post-rollback` | after rollback |
| `test` | on `helm test` |

## Values & Overrides

```yaml
# values.yaml
replicaCount: 3

image:
  repository: nginx
  tag: "1.25"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: app.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: app-tls
      hosts: [app.example.com]

resources:
  limits:
    cpu: 500m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70

env:
  - name: LOG_LEVEL
    value: info
  - name: DB_URL
    valueFrom:
      secretKeyRef:
        name: db
        key: url
```

```bash
# Override priority (low → high):
# values.yaml → --set → --set-string → --set-file → -f/--values
helm install release . -f prod.yaml --set image.tag=1.2 --set-string env=prod
```

## Template Functions & Pipelines

```yaml
# Built-in objects
{{ .Release.Name }}
{{ .Release.Namespace }}
{{ .Release.Service }}
{{ .Release.Revision }}
{{ .Chart.Name }}
{{ .Chart.Version }}
{{ .Chart.AppVersion }}
{{ .Values.replicaCount }}
{{ .Files.Get "config.properties" }}
{{ .Files.GetConfig "config.properties" }}

# Strings
{{ upper .Values.name }}
{{ lower .Values.name }}
{{ quote .Values.name }}
{{ .Values.name | default "default" | quote }}
{{ .Values.name | indent 4 }}
{{ .Values.name | nindent 4 }}
{{ .Values.name | trim }}
{{ trimPrefix "pre" .Values.name }}
{{ trimSuffix "suf" .Values.name }}
{{ .Values.name | repeat 3 }}
{{ .Values.list | join ", " }}

# Numbers
{{ add 1 2 }} {{ sub 10 3 }}
{{ mul 2 3 }} {{ div 10 3 }}
{{ max 3 5 }} {{ min 3 5 }}
{{ ceil 1.1 }} {{ floor 1.9 }}

# Booleans
{{ .Values.enabled | ternary "yes" "no" }}

# Collections
{{ .Values.list | first }}
{{ .Values.list | last }}
{{ .Values.list | rest }}
{{ .Values.list | uniq }}
{{ len .Values.list }}
{{ .Values.list | has "foo" }}
{{ .Values.dict | keys }}
{{ .Values.dict | values }}
{{ merge .Values.dict .Values.defaults }}

# Type
{{ kindOf .Values.port }}     # "float64"
{{ typeOf .Values.port }}     # float64
{{ .Values.port | toString }}
{{ .Values.port | toJson }}
{{ .Values.port | fromJson }}

# Regex
{{ regexMatch "^[a-z]+$" .Values.name }}
{{ regexFind "a(b+)" "aabbb" }}
{{ regexReplaceAll "old" "oldold" "new" }}
{{ regexReplaceAllLiteral "old" "oldold" "new" }}

# Encoding
{{ .Values.data | b64enc }}
{{ .Values.encoded | b64dec }}
{{ .Values.data | sha256sum }}
{{ "pass" | htpasswd }}

# Date
{{ now | date "2006-01-02" }}
{{ ago "2024-01-01" }}

# Flow
{{- if .Values.ingress.enabled }}
{{- else if .Values.ingress.disabled }}
{{- end }}

{{- range .Values.ports }}
  - port: {{ . }}
{{- end }}

{{- range $key, $val := .Values.env }}
  {{ $key }}: {{ $val }}
{{- end }}

{{- with .Values.service }}
  port: {{ .port }}
  type: {{ .type }}
{{- end }}

{{- $global := .Values.global -}}
```

## Named Templates (_helpers.tpl)

```yaml
{{- define "myapp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "myapp.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "myapp.labels" -}}
helm.sh/chart: {{ include "myapp.name" . }}-{{ .Chart.Version }}
app.kubernetes.io/name: {{ include "myapp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "myapp.selectorLabels" -}}
app.kubernetes.io/name: {{ include "myapp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "myapp.image" -}}
{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}
{{- end }}
```

Usage in templates:

```yaml
metadata:
  name: {{ include "myapp.fullname" . }}
  labels:
    {{- include "myapp.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "myapp.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "myapp.selectorLabels" . | nindent 8 }}
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ include "myapp.image" . }}"
```

## Dependencies

```yaml
# Chart.yaml
dependencies:
  - name: postgresql
    version: "~12.0"
    repository: https://charts.bitnami.com/bitnami
    condition: postgresql.enabled
    tags:
      - database
    alias: db
```

```bash
helm dependency update  # downloads to charts/
helm dependency build   # download from lock file
helm dependency list
```

Access subchart values: `{{ .Values.db.postgresql.auth.database }}`

## Subcharts & Global Values

```yaml
# root values.yaml
global:
  environment: prod
  imageRegistry: registry.example.com

# subchart accesses via .Values.global
```

## Library Charts

```yaml
# Chart.yaml
type: library
```

```yaml
# templates/_common.tpl (in library chart)
{{- define "common.labels" -}}
app: {{ .Chart.Name }}
{{- end }}
```

```yaml
# consumer chart
dependencies:
  - name: common
    version: "1.x"
    repository: file://../common
```

## Schema Validation (values.schema.json)

```json
{
  "$schema": "https://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["image", "service"],
  "properties": {
    "replicaCount": {
      "type": "integer",
      "minimum": 1,
      "maximum": 100
    },
    "image": {
      "type": "object",
      "required": ["repository"],
      "properties": {
        "repository": { "type": "string" },
        "tag": { "type": "string" },
        "pullPolicy": {
          "type": "string",
          "enum": ["Always", "IfNotPresent", "Never"]
        }
      }
    }
  }
}
```

## Commands

```bash
# Create
helm create mychart

# Install / Upgrade
helm install release-name ./mychart
helm install release-name ./mychart -f prod.yaml --set image.tag=1.2
helm upgrade release-name ./mychart --install --atomic --timeout 5m
helm upgrade --reset-values      # reset to chart defaults
helm upgrade --reuse-values      # keep all previous values

# Rollback
helm rollback release-name 1
helm rollback release-name 1 --wait --timeout 5m

# Uninstall
helm uninstall release-name
helm uninstall release-name --keep-history

# List
helm list -A
helm list -n ns --all --failed

# Get Info
helm status release-name
helm history release-name
helm get values release-name          # current values
helm get values release-name --all    # all (merged)
helm get manifest release-name        # rendered k8s YAML
helm get notes release-name

# Test
helm test release-name
helm test release-name --logs

# Template (render locally, no cluster)
helm template release-name ./mychart
helm template release-name ./mychart -f prod.yaml --debug
helm template . --output-dir ./rendered
helm install --dry-run --debug

# Package / Publish
helm package ./mychart -d ./packages
helm push mychart-0.1.0.tgz oci://registry.example.com/charts
helm repo index ./packages

# Repo Management
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm repo list
helm repo remove bitnami
helm search repo nginx
helm search hub nginx          # artifact hub

# Plugin
helm plugin install https://github.com/databus23/helm-diff
helm diff upgrade release-name ./mychart -f prod.yaml
```

## Best Practices

- Pin dependency versions (`~12.0`, not `*`)
- Use `--atomic` to auto-rollback on failure
- Render with `helm template` in CI to validate
- Separate environments via `values-{env}.yaml`
- Keep `values.yaml` minimal with sensible defaults
- Use `required` for mandatory values:
  ```yaml
  dbUrl: {{ required "db.url is required" .Values.db.url }}
  ```
- Don't nest more than 3 levels deep
- Use `lookup` to check existing resources:
  ```yaml
  {{- if not (lookup "v1" "Namespace" "" .Release.Namespace) }}
  apiVersion: v1
  kind: Namespace
  ...
  {{- end }}
  ```
- Use `include` (not `template`) for named templates (supports pipelines)
- Add `NOTES.txt` for post-install instructions
- Write tests in `templates/tests/`
- Use `helm lint` before packaging
- Sign charts with `--sign` for supply chain security
