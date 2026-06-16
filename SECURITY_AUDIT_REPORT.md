# Security Audit Report — `kutija_sa_peskom`

**Date:** 2026-06-10 (updated)
**Repository:** `/home/ivan/work/kutija_sa_peskom`
**Status:** Not a git repository (no `.git` folder), but files exist on disk

---

## Summary

| Severity | Count |
|----------|-------|
| 🔴 **High** | 4 |
| 🟡 **Medium** | 6 |
| 🟢 **Low / Info** | 9 |

**Overall verdict: ⚠️ NOT SAFE to push to a public repository without remediation.**

The repository contains real credentials, a private SSH key, a TLS private key, and build artifacts. If git is initialized and pushed to a public remote, sensitive infrastructure secrets would be exposed. A `.gitignore` has been created (see below) but the sensitive files already on disk are still present.

---

## 🔴 High Severity Issues

### H1 — Vagrant SSH Private Key committed

| File | Line | Content |
|------|------|---------|
| `kubernetes/kubernetes_k3s-single-node/.vagrant/machines/default/libvirt/private_key` | 1 | `-----BEGIN RSA PRIVATE KEY-----` |

A full 2048-bit RSA private key that grants SSH access to a Vagrant VM. This is a real, usable key — not a dummy or placeholder.

**Action:** Delete the `.vagrant/` directory. (`.gitignore` already updated.)

---

### H2 — Hardcoded MariaDB root password (plaintext)

| File | Line | Content |
|------|------|---------|
| `kubernetes_deployments/mariadb.yaml` | 8 | `MYSQL_ROOT_PASSWORD: ysgMmcOrARgHWPfb` |
| `kubernetes_deployments/mariadb.yaml` | 10 | `MYSQL_USER: demo` |
| `kubernetes_deployments/mariadb.yaml` | 11 | `MYSQL_PASSWORD: demo123` |

Real-looking auto-generated root password (`ysgMmcOrARgHWPfb`) and a secondary user credential hardcoded in a Kubernetes Secret manifest. Passwords should use `secretRef` or be injected at deploy time.

**Action:** Replace with references to a real secrets manager or template variable.

---

### H3 — Hardcoded WordPress database credentials

| File | Line | Content |
|------|------|---------|
| `kubernetes_deployments/hello-world.yaml` | 41–42 | `WORDPRESS_DB_PASSWORD: demo123`, `WORDPRESS_DB_USER: demo` |

Credentials embedded directly in a Deployment manifest instead of using Kubernetes `secretKeyRef`.

**Action:** Move to a Secret object and reference via `valueFrom.secretKeyRef`.

---

### H4 — TLS Private Key committed (base64-encoded)

| File | Line | Content |
|------|------|---------|
| `kubernetes_helm/mariadb/depl/05-tls-secret.yaml` | 12 | `tls.key: LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0t...` |

A self-signed TLS certificate and private key (RSA) for `db.test`. The private key decodes from base64 to a valid `-----BEGIN PRIVATE KEY-----` PEM. Both certificate and key are committed in a static manifest.

**Action:** Generate at deploy time with a tool like `cert-manager` or a Helm `genSignedCert` helper. Remove the static file.

---

## 🟡 Medium Severity Issues

### M1 — `.vagrant/` directories committed across 5 projects

| Directory | Contains |
|-----------|----------|
| `simple_vm/.vagrant/` | Bundler/index state, machine IDs |
| `vm_image_builder/.vagrant/` | Bundler/index state |
| `kubernetes/kubernetes_k3s-single-node/.vagrant/` | **SSH private key** (H1 above) |
| `kubernetes/kubernetes_k8s-two-nodes/.vagrant/` | Bundler/index state |

`.vagrant/` directories contain machine-specific state and should never be committed.

**Note:** `docker_basic/` and `docker_swarm/` have `.gitignore` files with `.vagrant/` but no `.vagrant/` directory on disk yet.

**Action:** Remove all `.vagrant/` directories. (`.gitignore` already updated.)

---

### M2 — Python bytecache committed

| File |
|------|
| `application_examples/simple_messageboard/__pycache__/server.cpython-314.pyc` |

Compiled Python bytecode is platform-specific and should not be versioned.

**Action:** Delete the `__pycache__/` directory. (`.gitignore` already updated.)

---

### M3 — Default password "changeme" in Kubernetes Secret

| File | Line | Content |
|------|------|---------|
| `kubernetes_helm/mariadb/depl/01-secret.yaml` | 12 | `root-password: Y2hhbmdlbWU=` (base64 for `changeme`) |

While this is explicitly a placeholder, it is a hardcoded static password in a committed file. If deployed as-is without overriding, the database would have a well-known default password.

**Action:** Replace with a Helm template variable or omit the default.

---

### M4 — Dummy AWS credentials (low risk, but scanner-triggering)

| File | Lines | Content |
|------|-------|---------|
| `aws_api_gateway/floci-demo.sh` | 9–10 | `AWS_ACCESS_KEY="test"`, `AWS_SECRET_KEY="test"` |
| `local_aws_services/floci-demo.sh` | 11–12 | `AWS_ACCESS_KEY="test"`, `AWS_SECRET_KEY="test"` |
| `local_aws_services/floci_python_example.py` | 14–15 | `AWS_ACCESS_KEY = "test"`, `AWS_SECRET_KEY = "test"` |
| `kubernetes/kubernetes_helm/floci/README.md` | 19 | `export AWS_SECRET_ACCESS_KEY=test` |
| `kubernetes/kubernetes_helm/floci/templates/NOTES.txt` | 23 | `export AWS_SECRET_ACCESS_KEY=test` |

These are dummy credentials for a local AWS emulator (localstack/floci). They are not real, but automated security scanners will flag them.

**Action:** Consider using environment variables with clear comments that these are for local development only.

---

### M5 — Ansible inventory exposes SSH key paths

| File | Line | Content |
|------|------|---------|
| `ansible_automation/inventory/production/hosts.yml` | 23 | `ansible_ssh_private_key_file: ~/.ssh/production_key` |
| `ansible_automation/inventory/staging/hosts.yml` | 18 | `ansible_ssh_private_key_file: ~/.ssh/staging_key` |

Exposes SSH private key paths for production and staging environments. These reference real SSH keys — if those key files are also present on disk this is a high-severity issue.

**Action:** Move sensitive paths to Ansible vault or environment-specific variables.

---

### M6 — `.gitignore` files now created (was missing)

A root `.gitignore` has been added covering `.vagrant/`, `__pycache__/`, `*.pyc`, `*.pem`, `*.key`, `*.cert`, `.env`, `.DS_Store`, and `.idea/`.

Per-project `.gitignore` files exist for:
- `.vagrant/` exclusion: `simple_vm/.gitignore`, `vm_image_builder/.gitignore`, `kubernetes/kubernetes_k3s-single-node/.gitignore`, `kubernetes/kubernetes_k8s-two-nodes/.gitignore`, `docker_basic/.gitignore`, `docker_swarm/.gitignore`
- Python cache: `aws_api_gateway/.gitignore` (`__pycache__/`, `*.pyc`, `.env`)
- Ansible: `ansible_automation/.gitignore` (`*.retry`, `/tmp/ansible_cache/`, `collections/`, `.vagrant/`)

**Note:** Sensitive files already on disk (`.vagrant/` dirs, `__pycache__/`, etc.) still exist and must be deleted manually — the `.gitignore` only prevents future `git add` from tracking them.

---

## 🟢 Low Severity / Informational

| Item | File | Notes |
|------|------|-------|
| Placeholder passwords | `kubernetes_helm/opencode/values.yaml` | Empty string `password: ""` — safe |
| TLS cert reference | `kubernetes_deployments/docker-registry.yaml:113` | `secretName: registry-tls` — reference only, no value |
| Helm template certs | `kubernetes_helm/opencode/templates/tls-secret.yaml` | Uses `genSignedCert` — generates at deploy time |
| Helm template secrets | `kubernetes_helm/mariadb/templates/db-secret.yaml` | `{{ .Values.mariadb.rootPassword \| b64enc }}` — variable, not hardcoded |
| Ephemeral cert script | `application_examples/simple_messageboard/kubernetes/gen-tls-secret.sh` | Runtime cert generation, no stored secrets |
| Internal IPs in docs | `ai_written_guidelines/` | RFC1918 addresses (10.0.0.x, 192.168.x.x) — documentation examples |
| Default password in app | `application_examples/simple_messageboard/server.py:15` | `DB_PASSWORD = 'changeme'` — fallback default, production uses env vars |
| Doc example password | `docker_basic/DOCKER_LEARNING_GUIDE.md:218,332` | `POSTGRES_PASSWORD: example/secret` — teaching examples only |
| Doc example password | `docker_swarm/DOCKER_SWARM_LEARNING_GUIDE.md:345` | `POSTGRES_PASSWORD=secret` — teaching example only |

### New directories not audited

The following directories were added after the original audit and have not been fully reviewed for secrets:
`kubernetes/kubernetes_k8s-two-nodes/`, `kubernetes/kubernetes_argo/`, `kubernetes/kubernetes_deployments/apache-hello-world.yaml`, `kubernetes/kubernetes_deployments/debian/`, `kubernetes/kubernetes_deployments/image-builder/`, `kubernetes/kubernetes_deployments/opencode-ui/`, `kubernetes/kubernetes_deployments/regui/`, `kubernetes/kubernetes_helm/floci/`, `application_examples/helloworld/`, `docker_basic/`, `docker_swarm/`, `pytest_examples/`

A spot-check of these revealed no additional hardcoded real credentials beyond what is already listed above.

---

## Recommended Remediation Checklist

- [ ] Delete all `.vagrant/` directories (including `kubernetes/kubernetes_k8s-two-nodes/.vagrant/`)
- [ ] Delete `__pycache__/` directories
- [x] Root `.gitignore` created
- [ ] Remove static TLS key from `kubernetes/kubernetes_helm/mariadb/depl/05-tls-secret.yaml`
- [ ] Replace hardcoded passwords in `kubernetes/kubernetes_deployments/mariadb.yaml` with `secretKeyRef`
- [ ] Replace hardcoded passwords in `kubernetes/kubernetes_deployments/hello-world.yaml` with `secretKeyRef`
- [ ] Replace static `changeme` in `kubernetes/kubernetes_helm/mariadb/depl/01-secret.yaml` with template variable
- [ ] Review `ansible_automation/inventory/production/hosts.yml` and `staging/hosts.yml` for SSH key paths
- [ ] Review dummy AWS credentials across all floci files — add clear comments or remove
- [ ] Review dummy creds in `kubernetes/kubernetes_helm/floci/README.md` and `templates/NOTES.txt`
- [ ] Review doc examples with passwords in `docker_basic/DOCKER_LEARNING_GUIDE.md` and `docker_swarm/DOCKER_SWARM_LEARNING_GUIDE.md`
- [ ] Initialize a fresh git repository and do NOT commit any of the above
