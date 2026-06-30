# GitHub Actions — DevOps Cheatsheet

## Workflow Structure

```yaml
name: Deploy
run-name: "Deploy ${{ inputs.env }} by @${{ github.actor }}"  # optional

on:
  push:
    branches: [main]
    paths-ignore: ['**.md']
  pull_request:
    branches: [main]
    types: [opened, synchronize]
  workflow_dispatch:
    inputs:
      env:
        description: 'Target environment'
        required: true
        default: 'staging'
        type: choice
        options: [dev, staging, prod]
  schedule:
    - cron: '0 6 * * *'

env:
  NODE_VERSION: '20'
  REGISTRY: ghcr.io

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

defaults:
  run:
    shell: bash
    working-directory: ./app

jobs:
  lint:
    runs-on: ubuntu-latest
    timeout-minutes: 10
    strategy:
      matrix:
        node: [18, 20]
      fail-fast: false
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
          cache: 'npm'
      - run: npm ci
      - run: npm run lint

  test:
    needs: lint
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: test
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
      - run: npm ci && npm test

  build:
    needs: test
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    outputs:
      tag: ${{ steps.meta.outputs.tags }}
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - uses: docker/metadata-action@v5
        id: meta
        with:
          images: ${{ env.REGISTRY }}/${{ github.repository }}
          tags: |
            type=semver,pattern={{version}}
            type=sha
            type=ref,event=branch
      - uses: docker/build-push-action@v5
        with:
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment: ${{ inputs.env || 'staging' }}
    steps:
      - run: echo "Deploy ${{ needs.build.outputs.tag }} to ${{ github.ref_name }}"
```

## Triggers (`on`)

```yaml
on:
  push:                              # branch push + tags
  pull_request:                      # PR events
  release:                           # release published
  workflow_dispatch:                 # manual
  workflow_call:                     # reusable workflow
  schedule:                          # cron
  repository_dispatch:               # webhook from external
  page_build:                        # GitHub Pages
  status:                            # commit status

  # specific
  push:
    branches: [main, 'feature/*']
    tags: ['v*']
    paths: ['src/**', '!**.md']
  pull_request:
    types: [opened, reopened, synchronize, closed]
```

## Conditionals

```yaml
# job-level
if: github.ref == 'refs/heads/main'
if: startsWith(github.ref, 'refs/tags/v')
if: github.event_name == 'push'
if: contains(github.event.head_commit.message, '[skip ci]')
if: success() || failure()
if: always()
if: cancelled()

# step-level
steps:
  - if: steps.build.outputs.exitcode == 0
    run: echo "OK"
```

## Contexts & Expressions

```yaml
${{ github.actor }}
${{ github.repository }}
${{ github.ref }}
${{ github.ref_name }}
${{ github.sha }}
${{ github.event_name }}
${{ github.workflow }}
${{ github.job }}
${{ github.run_id }}
${{ github.run_number }}
${{ github.server_url }}
${{ github.token }}

${{ env.VAR }}
${{ vars.CONFIG }}            # org/repo-level variables
${{ secrets.SECRET }}
${{ inputs.env }}

${{ needs.build.outputs.tag }}
${{ steps.meta.outputs.tags }}
${{ strategy.matrix.node }}
${{ matrix.node }}
```

### Expression Functions

```yaml
${{ contains('hello', 'ell') }}
${{ startsWith('hello', 'he') }}
${{ endsWith('hello', 'lo') }}
${{ format('Hello {0}', 'world') }}
${{ join(github.event.commits.*.message, ', ') }}
${{ toJSON(github) }}
${{ fromJSON(needs.build.outputs.json) }}
${{ hashFiles('**/package-lock.json') }}
${{ secrets.SECRET | default('fallback') }}   # default filter
```

## Matrix

```yaml
strategy:
  matrix:
    os: [ubuntu-latest, windows-latest]
    node: [18, 20]
    include:
      - os: ubuntu-latest
        node: 22
    exclude:
      - os: windows-latest
        node: 18
  fail-fast: true
  max-parallel: 3

steps:
  - run: echo "OS=${{ matrix.os }} Node=${{ matrix.node }}"
```

## Reusable Workflows

### Caller
```yaml
jobs:
  call-workflow:
    uses: org/repo/.github/workflows/reusable.yml@main
    with:
      env: staging
    secrets:
      token: ${{ secrets.GH_TOKEN }}
```

### Reusable (`.github/workflows/reusable.yml`)
```yaml
on:
  workflow_call:
    inputs:
      env:
        required: true
        type: string
    secrets:
      token:
        required: true
    outputs:
      result:
        value: ${{ jobs.run.outputs.result }}
        description: "deploy result"

jobs:
  run:
    runs-on: ubuntu-latest
    outputs:
      result: ${{ steps.out.outputs.value }}
    steps:
      - id: out
        run: echo "value=ok" >> $GITHUB_OUTPUT
```

## Caching

```yaml
- uses: actions/cache@v4
  with:
    path: |
      ~/.npm
      node_modules
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-node-
```

## Artifacts

```yaml
- uses: actions/upload-artifact@v4
  with:
    name: build-output
    path: dist/
    retention-days: 5

- uses: actions/download-artifact@v4
  with:
    name: build-output
    path: ./dist
```

## Environments & Protection Rules

```yaml
environment:
  name: prod
  url: https://myapp.io
```

```yaml
# .github/environments.yml (config via UI or API)
# - Required reviewers
# - Wait timer
# - Deployment branches
```

## Composite Actions

```yaml
# .github/actions/setup/action.yml
name: 'Setup'
inputs:
  node-version:
    default: '20'
runs:
  using: 'composite'
  steps:
    - uses: actions/setup-node@v4
      with:
        node-version: ${{ inputs.node-version }}
    - run: npm ci
      shell: bash
```

## Common Patterns

```yaml
# label-based PR check
if: github.event.pull_request.labels.*.name.contains('safe-to-deploy')

# branch protection not on PR
if: github.event_name == 'push' && github.ref == 'refs/heads/main'

# lint + comment on PR
- uses: actions/github-script@v7
  with:
    script: |
      github.rest.issues.createComment({
        issue_number: context.issue.number,
        owner: context.repo.owner,
        repo: context.repo.repo,
        body: '✅ Lint passed'
      })

# auto-cancel old runs
concurrency:
  group: ${{ github.workflow }}-${{ github.head_ref || github.run_id }}
  cancel-in-progress: true

# version from tag
- run: echo "VERSION=${GITHUB_REF#refs/tags/v}" >> $GITHUB_ENV

# commit status check
- run: exit 1
  continue-on-error: true
```

## Key Concepts

| Concept | Summary |
|---------|---------|
| **Workflow** | YAML file in `.github/workflows/` |
| **Job** | runs on a runner, has steps |
| **Step** | single unit (action or shell command) |
| **Action** | reusable unit (GH marketplace or local) |
| **Runner** | VM that executes jobs (GH-hosted or self-hosted) |
| **Event** | what triggers the workflow |
| **Context** | runtime info (`github.*`, `env.*`, `secrets.*`) |
| **Expression** | `${{ }}` — evaluated at runtime |
| **Matrix** | run job with multiple variants |
| **Service** | ephemeral sidecar container (DB, cache) |
| **Environment** | deployment target with protection rules |
| **Artifact** | persist files between jobs |
| **Cache** | speed up deps (npm, maven, docker) |
| **Composite** | bundle steps into reusable action |
| **Reusable** | call workflow from another workflow |
