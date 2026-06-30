# Argo CD & Workflows — DevOps Cheatsheet

## Argo CD — Core Concepts

| Concept | Summary |
|---------|---------|
| **Application** | k8s resource + source repo + destination cluster |
| **Project** | grouping of apps with RBAC + restrictions |
| **Sync** | reconcile desired vs live state |
| **Sync Waves** | ordered apply phases (annotations) |
| **Sync Phases** | PreSync → Sync → PostSync (hooks) |
| **Health** | app status (Healthy, Degraded, Progressing) |
| **Auto-sync** | automatic reconciliation on repo changes |
| **Prune** | delete resources removed from Git |
| **Self-heal** | correct manual changes to match Git |
| **App of Apps** | parent app that manages child apps |
| **SSO** | OIDC / Dex for UI login |
| **Repos** | Git repos containing k8s manifests |

## Argo CD — Application

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/org/repo.git
    targetRevision: main
    path: k8s/overlays/prod
    helm:
      valueFiles:
        - values-prod.yaml
      parameters:
        - name: image.tag
          value: v1.2.3
  destination:
    server: https://kubernetes.default.svc
    namespace: myapp
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
      - CreateNamespace=true
      - PruneLast=true
      - ApplyOutOfSyncOnly=true
    managedNamespaceMetadata:
      labels:
        team: platform
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

## Argo CD — Project

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: platform
  namespace: argocd
spec:
  description: Platform team apps
  sourceRepos:
    - 'https://github.com/org/*'
  destinations:
    - namespace: 'platform-*'
      server: 'https://kubernetes.default.svc'
  clusterResourceWhitelist:
    - group: ''
      kind: 'Namespace'
  orphanedResources:
    warn: false
  roles:
    - name: admin
      policies:
        - p, proj:platform:admin, applications, *, platform/*, allow
```

## CLI Commands

```bash
argocd login <server> --sso
argocd app list
argocd app get myapp
argocd app sync myapp
argocd app sync myapp --prune --apply-out-of-sync-only
argocd app diff myapp
argocd app wait myapp --health
argocd app create myapp --repo ... --path ... --dest-server ...
argocd app set myapp --auto-sync --self-heal
argocd app delete myapp
argocd app history myapp
argocd app rollback myapp 3

argocd proj list
argocd proj create platform
argocd proj add-destination platform 'https://...' 'staging-*'

argocd repo list
argocd repo add https://github.com/org/repo.git --ssh-private-key-path ~/.ssh/id_rsa

argocd cluster list
argocd cluster add <context>

argocd admin settings validate

argocd account update-password
```

## Sync Waves & Hooks

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "-5"  # earlier = lower number

---
apiVersion: batch/v1
kind: Job
metadata:
  name: db-migration
  annotations:
    argocd.argoproj.io/hook: PreSync
    argocd.argoproj.io/hook-delete-policy: HookSucceeded
spec:
  template:
    spec:
      containers:
        - name: migrate
          image: myapp:latest
          command: ["./migrate"]
      restartPolicy: Never
```

### Hook Types
| Hook | When |
|------|------|
| `PreSync` | before sync |
| `Sync` | during sync (replace resources) |
| `PostSync` | after sync success |
| `Skip` | skip resource |
| `SyncFail` | on sync failure |

## App of Apps Pattern

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: apps
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/org/cluster.git
    path: apps
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
```

Directory `apps/` contains `app-platform.yaml`, `app-monitoring.yaml`, etc.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: platform
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/org/cluster.git
    path: apps/platform
  destination:
    server: https://kubernetes.default.svc
    namespace: platform
```

## ApplicationSet

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: myapps
spec:
  generators:
    - git:
        repoURL: https://github.com/org/cluster.git
        revision: main
        directories:
          - path: apps/*
    - clusters: {}          # one app per cluster
    - list:
        elements:
          - name: dev
            namespace: dev
          - name: prod
            namespace: prod
    - matrix:
        generators:
          - git: ...
          - list: ...
  template:
    metadata:
      name: '{{name}}-app'
    spec:
      project: default
      source:
        repoURL: https://github.com/org/repo.git
        targetRevision: main
        path: 'k8s/{{name}}'
      destination:
        namespace: '{{namespace}}'
        server: '{{cluster.server}}'
```

## Argo Workflows — Basics

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: hello-
spec:
  entrypoint: main
  arguments:
    parameters:
      - name: msg
        value: hello
  templates:
    - name: main
      steps:
        - - name: greet
            template: echo
            arguments:
              parameters: [{name: msg, value: '{{workflow.parameters.msg}}'}]
        - - name: done
            template: echo
            arguments:
              parameters: [{name: msg, value: "done"}]

    - name: echo
      inputs:
        parameters:
          - name: msg
      container:
        image: alpine:latest
        command: [echo, '{{inputs.parameters.msg}}']
```

## Argo Workflows — DAG

```yaml
spec:
  entrypoint: dag
  templates:
    - name: dag
      dag:
        tasks:
          - name: build
            template: echo
            arguments:
              parameters: [{name: msg, value: build}]
          - name: test
            template: echo
            dependencies: [build]
            arguments:
              parameters: [{name: msg, value: test}]
          - name: lint
            template: echo
            dependencies: [build]
          - name: deploy
            template: echo
            dependencies: [test, lint]
```

## Argo Workflows — Artifacts & Outputs

```yaml
templates:
  - name: produce
    container:
      image: alpine
      command: [sh, -c, 'echo data > /out/result.txt']
    outputs:
      artifacts:
        - name: result
          path: /out/result.txt
          s3:
            bucket: my-bucket
            key: 'results/{{workflow.name}}/result.txt'
  - name: consume
    inputs:
      artifacts:
        - name: result
          path: /in/result.txt
          s3:
            bucket: my-bucket
            key: 'results/{{workflow.name}}/result.txt'
```

## Argo Workflows — CLI

```bash
argo submit workflow.yaml
argo submit -p msg=hello workflow.yaml
argo list
argo get <name>
argo logs <name> --tail=20
argo delete <name>
argo stop <name>
argo resubmit <name>
argo retry <name>
argo wait <name>
argo template lint workflow.yaml
```

## Key Concepts

| Argo CD | Summary |
|---------|---------|
| **GitOps** | Git is single source of truth |
| **Sync** | reconcile Git → cluster |
| **Auto-sync** | automatic reconcile on Git push |
| **Self-heal** | revert manual changes |
| **Prune** | delete resources not in Git |
| **App of Apps** | declarative app management |
| **ApplicationSet** | generate apps from generators |
| **Sync Waves** | ordering within sync |
| **Hooks** | jobs before/after sync |
| **SSO** | OIDC integration |

| Argo Workflows | Summary |
|------------|---------|
| **Template** | reusable step definition |
| **Step** | sequential execution |
| **DAG** | dependency-driven execution |
| **Artifact** | pass files between steps (S3/GCS) |
| **Parameter** | input/output values |
| **CronWorkflow** | scheduled workflow |
| **WorkflowTemplate** | reusable workflow blueprint |
