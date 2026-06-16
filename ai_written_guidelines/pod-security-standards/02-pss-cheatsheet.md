# Pod Security Standards — CLI Cheatsheet

A practical reference for inspecting and managing Pod Security Standards on your Kubernetes cluster. Every command here assumes you have `kubectl` configured to point to your cluster.

> **Legend:** Three modes coexist on each namespace:
> - **`enforce`** — blocks pod creation that violates the policy
> - **`warn`** — allows the pod but shows a warning to the user running `kubectl`
> - **`audit`** — allows the pod but logs the violation to the API server audit log

---

## 1. View PSS Labels on All Namespaces

**What this does:** Lists every namespace in the cluster along with its Pod Security Standards labels. This is your overview — you can see at a glance which namespaces are enforcing what.

**The formatted version** (uses `jq` to pretty-print):

```bash
kubectl get ns -o json | jq -r '
  .items[]
  | select(.metadata.labels | keys | any(startswith("pod-security")))
  | "\(.metadata.name):",
    (.metadata.labels
      | to_entries
      | map(select(.key | startswith("pod-security")))
      | sort_by(.key)[]
      | "  \(.key): \(.value)"
    )
'
```

**Example output:**

```
default:
  pod-security.kubernetes.io/audit: restricted
  pod-security.kubernetes.io/audit-version: v1.35
  pod-security.kubernetes.io/warn: restricted
  pod-security.kubernetes.io/warn-version: v1.35
kube-system:
  pod-security.kubernetes.io/enforce: privileged
  pod-security.kubernetes.io/enforce-version: v1.35
```

**The quick version** (use when you just need to confirm a label exists):

```bash
kubectl get ns -o json | jq -r '
  .items[].metadata.labels | to_entries[] | select(.key | startswith("pod-security")) |
  "\(.key): \(.value)"
'
```

**Sample output:**

```
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/audit-version: v1.35
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/warn-version: v1.35
    pod-security.kubernetes.io/enforce: privileged
    pod-security.kubernetes.io/enforce-version: v1.35
```

> **What to look for:** Namespaces with no PSS labels at all have **no protection**. Namespaces that only have `warn`/`audit` are still allowing violations — they're just reporting them. Only `enforce` actually blocks non-compliant pods.

---

## 2. View PSS Labels on a Single Namespace

**What this does:** Shows the PSS labels for just one namespace. Useful when you want to focus on a specific workload without the noise of other namespaces.

```bash
kubectl get ns <namespace> -o json | jq -r '
  .metadata.labels | to_entries[] | select(.key | startswith("pod-security")) |
  "\(.key): \(.value)"
'
```

**Real example:**

```bash
kubectl get ns default -o json | jq -r '
  .metadata.labels | to_entries[] | select(.key | startswith("pod-security")) |
  "\(.key): \(.value)"
'

**Output:**

```
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/audit-version: v1.35
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/warn-version: v1.35
```

**What this tells you:** The `default` namespace currently warns and audits against Restricted but does **not** enforce anything. Pods violating Restricted will still be created — they just trigger a warning and an audit log entry.

---

## 3. Test a Pod Against the Enforced Policy (Dry-Run)

### Basic check — will this pod be blocked?

**What this does:** Submits the pod creation request to the API server but doesn't actually create the pod. The server evaluates it against the namespace's `enforce`, `warn`, and `audit` labels and returns any violations.

```bash
kubectl run <name> --image=<image> --restart=Never -n <namespace> --dry-run=server
```

**Real example — test a plain nginx pod against the `default` namespace:**

```bash
kubectl run nginx-test --image=nginx --restart=Never -n default --dry-run=server
```

**Sample output:**

```
Warning: would violate PodSecurity "restricted:v1.35": allowPrivilegeEscalation != false
(container "nginx-test" must set securityContext.allowPrivilegeEscalation=false),
unrestricted capabilities (container "nginx-test" must set
securityContext.capabilities.drop=["ALL"]),
runAsNonRoot != true (pod or container "nginx-test" must set
securityContext.runAsNonRoot=true),
seccompProfile (pod or container "nginx-test" must set
securityContext.seccompProfile.type to "RuntimeDefault" or "Localhost")
pod/nginx-test created (server dry run)
```

**How to read this output:**
- The `Warning:` line lists every control the pod violates
- `pod/nginx-test created (server dry run)` means the pod **was not actually created** — it's just reporting what would happen
- If the namespace had `enforce: restricted` instead of just `warn`, the API server would **reject** the request instead of showing a warning

**Important caveat:** `--dry-run=server` only checks admission plugins that run **server-side**. It does not check mutating webhooks or other admission controllers that might modify the pod after submission. Always test with a real pod in a non-production namespace for full confidence.

### Test with a compliant security context

**What this does:** The same dry-run test but with the correct `securityContext` settings so the pod passes Restricted. This is useful for verifying that your security context changes are correct before rolling them out.

```bash
kubectl run nginx-test --image=nginx --restart=Never -n default \
  --dry-run=server \
  --overrides='{
    "spec": {
      "securityContext": {
        "runAsNonRoot": true,
        "seccompProfile": {"type": "RuntimeDefault"}
      },
      "containers": [{
        "name": "nginx-test",
        "image": "nginx",
        "securityContext": {
          "allowPrivilegeEscalation": false,
          "capabilities": {"drop": ["ALL"]}
        }
      }]
    }
  }'
```

**Expected output (no warnings):**

```
pod/nginx-test created (server dry run)
```

**Why this works:** The overrides add:
- `runAsNonRoot: true` — satisfies the non-root requirement
- `seccompProfile.type: RuntimeDefault` — satisfies the seccomp requirement
- `allowPrivilegeEscalation: false` — prevents privilege escalation
- `capabilities.drop: ["ALL"]` — drops all Linux capabilities (Restricted allows re-adding only `NET_BIND_SERVICE` if needed)

### Test against Baseline vs Restricted

**What this does:** Shows how the same pod fares under different policies. Useful when deciding which profile to apply.

```bash
# Test against Baseline
kubectl run nginx-test --image=nginx --restart=Never -n debug --dry-run=server
# Assuming 'debug' has enforce=baseline — this should pass

# Test against Restricted
kubectl run nginx-test --image=nginx --restart=Never -n default --dry-run=server
# Assuming 'default' has warn=restricted — this will show warnings
```

---

## 4. Check Audit Logs

### Understanding what audit mode actually does

The `audit` mode adds entries to the **API server audit log** whenever a pod violates the policy. It does **not**:

- Generate Kubernetes events (`kubectl get events` will show nothing)
- Block the pod
- Show warnings to the user

This makes audit mode useful for **measuring impact** before switching to enforcement — you can let it run for a few days, then check how many violations occurred.

### Check via Kubernetes events (usually empty)

```bash
kubectl get events -A --field-selector reason=FailedValidation
```

**Expected output (usually):**

```
No resources found
```

**Why it's empty:** PSS audit violations do **not** create Kubernetes events. They only write to the API server audit log. If you see events here, they're coming from a different admission controller (like Kyverno or OPA Gatekeeper).

### View the API Server Audit Log (k3s)

**What this does:** Tails the raw API server audit log and filters for PSS-related entries. This is where `audit` mode violations actually appear.

**Prerequisite — enable audit logging in k3s:**

k3s does **not** enable the API server audit log by default. Add this to `/etc/rancher/k3s/config.yaml`:

```yaml
kube-apiserver-arg:
  - "audit-log-path=/var/lib/rancher/k3s/server/audit.log"
  - "audit-log-maxage=7"
  - "audit-log-maxbackup=10"
  - "audit-log-maxsize=100"
```

Then restart k3s:

```bash
sudo systemctl restart k3s
# or if using a different init system:
# sudo rc-service k3s restart
```

Once enabled, tail the audit log and filter for PSS entries:

```bash
# Watch live
sudo tail -f /var/lib/rancher/k3s/server/audit.log | grep -i "pod-security"

# Search past entries
sudo grep -i "pod-security" /var/lib/rancher/k3s/server/audit.log
```

**What you'll see in the log (JSON lines):**

```json
{
  "kind": "Event",
  "level": "Metadata",
  "auditID": "...",
  "annotations": {
    "pod-security.kubernetes.io/audit-violations": "would violate PodSecurity \"restricted:v1.35\": ...",
    "pod-security.kubernetes.io/audit-version": "v1.35"
  },
  "objectRef": {
    "resource": "pods",
    "namespace": "default",
    "name": "nginx-test"
  }
}
```

**How to parse useful info from the JSON log:**

```bash
# Extract just the namespace, pod name, and violation reason
sudo grep -i "pod-security" /var/lib/rancher/k3s/server/audit.log | \
  jq -r '
    select(.annotations["pod-security.kubernetes.io/audit-violations"]) |
    "\(.objectRef.namespace // "?")/\(.objectRef.name // "?"): \(.annotations["pod-security.kubernetes.io/audit-violations"][:100])..."
  '
```

### Check via Central Logging (Loki, Elastic, Datadog, etc.)

**What this does:** If you ship API server audit logs to a central logging system, search for the annotation that PSS audit mode adds to every violating request.

**Search term:**

```
pod-security.kubernetes.io/audit-violations
```

**Sample query (PromQL/Loki LogQL):**

```
{namespace="default"} |= "pod-security.kubernetes.io/audit-violations"
```

**Kibana / Elasticsearch:**

```json
{
  "query": {
    "exists": {
      "field": "annotations.pod-security.kubernetes.io/audit-violations"
    }
  }
}
```

---

## 5. Check If a Running Pod Is Compliant

**What this does:** Inspects the `securityContext` of a running pod to see if it would pass the namespace's PSS policy. This helps you identify which workloads need changes before you switch from `warn`/`audit` to `enforce`.

```bash
kubectl get pod <name> -n <namespace> -o yaml | grep -A10 securityContext
```

**Real example:**

```bash
kubectl get pod floci-6f769f8565-9qrvd -n default -o yaml | grep -A10 securityContext
```

**Sample output:**

```yaml
    securityContext:
      capabilities:
        add:
        - NET_ADMIN
        - NET_RAW
        - SYS_PTRACE
      runAsUser: 0
--
  securityContext:
    fsGroup: 1000
    runAsNonRoot: false
```

**How to evaluate this against the policies:**

| Setting | Privileged | Baseline | Restricted |
|---|---|---|---|
| `runAsUser: 0` | ✅ Allowed | ✅ Allowed | ❌ Must not be 0 |
| `runAsNonRoot: false` | ✅ Allowed | ✅ Allowed | ❌ Must be `true` |
| `capabilities.add: [NET_ADMIN, NET_RAW, SYS_PTRACE]` | ✅ Any | ❌ Only safe list | ❌ Must drop ALL first |

**What this means:** floci would fail **both Baseline and Restricted** enforcement because of the extra capabilities. If you want to enforce Baseline or Restricted on the `default` namespace, floci needs code changes first.

### Check all pods in a namespace for compliance

**What this does:** Quickly scans all pods in a namespace and reports whether each one has `runAsNonRoot`, `allowPrivilegeEscalation`, and seccomp set — the three most common Restricted requirements.

```bash
for pod in $(kubectl get pods -n default -o name); do
  echo "=== $pod ==="
  kubectl get "$pod" -n default -o yaml | grep -E 'runAsNonRoot|allowPrivilegeEscalation|seccompProfile|c apabilities'
done
```

---

## 6. Add or Update PSS Labels

**What this does:** Applies PSS labels to a namespace. You can apply `enforce`, `warn`, `audit`, or any combination. Always pin a version to ensure consistent behavior across cluster upgrades.

```bash
# Enforce Baseline — blocks pods that violate Baseline
kubectl label ns <namespace> \
  pod-security.kubernetes.io/enforce=baseline \
  pod-security.kubernetes.io/enforce-version=v1.35

# Warn + Audit Restricted — reports violations but allows pods
kubectl label ns <namespace> \
  pod-security.kubernetes.io/warn=restricted \
  pod-security.kubernetes.io/warn-version=v1.35 \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/audit-version=v1.35

# Full combo — enforce Baseline but warn about Restricted
kubectl label ns <namespace> \
  pod-security.kubernetes.io/enforce=baseline \
  pod-security.kubernetes.io/enforce-version=v1.35 \
  pod-security.kubernetes.io/warn=restricted \
  pod-security.kubernetes.io/warn-version=v1.35 \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/audit-version=v1.35
```

**Real-world strategy — gradual tightening:**

```bash
# Step 1 (today): Warn + Audit only — measure impact
kubectl label ns production \
  pod-security.kubernetes.io/warn=restricted \
  pod-security.kubernetes.io/warn-version=v1.35 \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/audit-version=v1.35

# Step 2 (next week): Switch to enforce after fixing violations
kubectl label ns production \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/enforce-version=v1.35 \
  pod-security.kubernetes.io/warn- \
  pod-security.kubernetes.io/audit-
```

**Version pinning explained:**

Always pin the version (`v1.35`) to match your Kubernetes server version. This ensures the policy checks remain consistent even after a cluster upgrade. If you don't pin, the policy uses the latest version known to the API server, which may change after an upgrade and unexpectedly break workloads.

---

## 7. Remove a PSS Label

**What this does:** Removes a specific PSS label from a namespace. Append a `-` suffix to the label key to remove it.

```bash
# Remove enforce
kubectl label ns <namespace> pod-security.kubernetes.io/enforce-

# Remove warn
kubectl label ns <namespace> pod-security.kubernetes.io/warn-

# Remove audit
kubectl label ns <namespace> pod-security.kubernetes.io/audit-

# Remove all PSS labels at once
kubectl label ns <namespace> \
  pod-security.kubernetes.io/enforce- \
  pod-security.kubernetes.io/enforce-version- \
  pod-security.kubernetes.io/warn- \
  pod-security.kubernetes.io/warn-version- \
  pod-security.kubernetes.io/audit- \
  pod-security.kubernetes.io/audit-version-
```

> **When to remove labels:** You might remove a label when migrating a namespace to a different policy engine (Kyverno, OPA), or when you want to temporarily disable PSS during troubleshooting.

---

## 8. Troubleshooting Common Scenarios

### Scenario A: "I applied enforce but pods are still being created"

```bash
# 1. Verify the label was applied correctly
kubectl get ns <namespace> -o json | jq -r '
  .metadata.labels | to_entries[] | select(.key | startswith("pod-security")) |
  "\(.key): \(.value)"
'

# 2. Check if the Pod Security Admission controller is enabled
kubectl -n kube-system get pods | grep admission

# 3. Try creating a violating pod — it should be rejected
kubectl run test --image=ubuntu --restart=Never -n <namespace> -- sleep 1000
# If the pod is created, PSS is not actually enforcing
```

### Scenario B: "I'm seeing 'would violate' warnings but I don't know what to fix"

The warning message tells you exactly what's wrong:

```
Warning: would violate PodSecurity "restricted:v1.35":
  - allowPrivilegeEscalation != false          → set securityContext.allowPrivilegeEscalation: false
  - unrestricted capabilities                   → set securityContext.capabilities.drop: ["ALL"]
  - runAsNonRoot != true                        → set securityContext.runAsNonRoot: true
  - seccompProfile                              → set securityContext.seccompProfile.type: "RuntimeDefault"
```

Fix each one in your pod spec, Deployment, or Helm values.

### Scenario C: "I need to know exactly which pods are violating right now"

Install a tool that checks existing pods against PSS:

```bash
# Using kubectl-neat (simplifies YAML output)
kubectl get pods -n default -o yaml | grep -B5 'securityContext:'

# Or check the audit log (if configured)
sudo grep "audit-violations" /var/lib/rancher/k3s/server/audit.log
```

---

## 9. How PSS Versioning Works

The label `pod-security.kubernetes.io/enforce-version: v1.35` does **not** mean "use the policy that was defined in Kubernetes v1.35." It means:

> "Apply the policy definitions as they were at Kubernetes **v1.35**."

This is important because Kubernetes occasionally adds new controls to a profile. Without a version pin, upgrading the cluster could suddenly enforce new rules that break your pods. With a pin, your policy stays stable until you explicitly update the version label.

**Upgrade strategy:**

```bash
# Before upgrading cluster from 1.35 to 1.36
# 1. Update the version pin to match the new server version
kubectl label ns <namespace> --overwrite \
  pod-security.kubernetes.io/enforce-version=v1.36

# 2. Test with dry-run before the actual upgrade
# 3. If pods fail, fix them first, then proceed with the upgrade
```

---

## Quick Reference: What to Run and When

| You Want To... | Command | Section |
|---|---|---|
| See all PSS labels across the cluster | `kubectl get ns -o json \| jq -r '...'` (see Section 1) | **1** |
| See PSS labels on one namespace | `kubectl get ns <name> -o json \| jq -r '...'` (see Section 2) | **2** |
| Check if a new pod would be blocked | `kubectl run ... --dry-run=server` | **3** |
| See `warn` violations | Run the pod command — warnings appear in stderr | **3** |
| See `audit` violations | Enable API server audit log, then grep it | **4** |
| Check if an existing pod is compliant | `kubectl get pod ... -o yaml \| grep -A10 securityContext` | **5** |
| Apply a policy to a namespace | `kubectl label ns ... pod-security.kubernetes.io/enforce=...` | **6** |
| Remove a policy from a namespace | `kubectl label ns ... pod-security.kubernetes.io/enforce-` | **7** |
| Troubleshoot why enforcement isn't working | Verify labels, check admission controller | **8** |

---

## Real-World Audit Log Check (No Setup Required)

If you haven't enabled the API server audit log, you can still see PSS violations in action by:

1. **Checking warnings** — create a pod against a `warn`-labeled namespace
2. **Using `--dry-run=server`** — simulates pod creation and shows violations
3. **Enabling Kubernetes audit logging** — follow the k3s config in Section 4

The most practical day-to-day workflow:

```bash
# 1. See what's currently enforced
kubectl get ns -o json | jq -r '
  .items[]
  | select(.metadata.labels | keys | any(startswith("pod-security")))
  | "\(.metadata.name):",
    (.metadata.labels
      | to_entries
      | map(select(.key | startswith("pod-security")))
      | sort_by(.key)[]
      | "  \(.key | split("/")[-1]): \(.value)"
    )
'

# 2. Test a problem pod
kubectl run probe --image=busybox --restart=Never -n default --dry-run=server -- sh

# 3. Clean up test pods (they don't exist, but just in case)
kubectl delete pod probe nginx-test --ignore-not-found -n default
```
