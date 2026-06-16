# nftables (Modern Replacement)

## What Is nftables?

nftables is the **modern replacement** for iptables. It's part of the same Netfilter framework but uses a **new syntax** and **single unified tool** (`nft`) instead of separate tools for IPv4, IPv6, ARP, and bridge (`iptables`, `ip6tables`, `arptables`, `ebtables`).

On many modern distributions (RHEL 9+, Fedora, Debian 11+, Ubuntu 22.04+), nftables is the default backend even when you run `iptables` — the `iptables` command is a compatibility wrapper that translates to nftables.

## Key Differences

| Aspect | iptables | nftables |
|--------|----------|----------|
| Tool count | 4+ separate tools (`iptables`, `ip6tables`, `arptables`, `ebtables`) | Single `nft` tool |
| Syntax | Per-command flags (`-A`, `-s`, `-j`) | Structured ruleset with tables, chains, rules |
| Multi-protocol | Separate tools for IPv4/IPv6 | Unified — one ruleset handles both |
| Atomic updates | No (rules apply one by one) | Yes (entire ruleset can be replaced atomically) |
| Performance | Fixed table/chain structure | Faster, no fixed limits |
| Sets/maps | External (`ipset` tool) | Built-in (`nft set`, `nft map`) |
| Backend | Kernel module `ip_tables` | Kernel module `nf_tables` |

## Syntax Comparison

### Listing Rules

```bash
# iptables
sudo iptables -L -n -v

# nftables
sudo nft list ruleset
```

### Basic Accept Rules

```bash
# iptables
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -P INPUT DROP

# nftables
sudo nft add rule inet filter input tcp dport 22 accept
sudo nft add rule inet filter input ct state established,related accept
sudo nft add rule inet filter input drop
```

### Full Ruleset Example

**iptables:**

```bash
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT

sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
sudo iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
```

**nftables equivalent:**

```bash
sudo nft flush ruleset

sudo nft add table inet filter
sudo nft add chain inet filter input   { type filter hook input priority 0; policy drop; }
sudo nft add chain inet filter forward { type filter hook forward priority 0; policy drop; }
sudo nft add chain inet filter output  { type filter hook output priority 0; policy accept; }

sudo nft add rule inet filter input iif lo accept
sudo nft add rule inet filter input ct state established,related accept
sudo nft add rule inet filter input tcp dport 22 accept
sudo nft add rule inet filter input tcp dport 80 accept
sudo nft add rule inet filter input tcp dport 443 accept
sudo nft add rule inet filter input ct state invalid drop
```

### NAT (Masquerade)

```bash
# iptables
sudo iptables -t nat -A POSTROUTING -o eth0 -s 10.0.0.0/24 -j MASQUERADE

# nftables
sudo nft add table nat
sudo nft add chain nat postrouting { type nat hook postrouting priority 100; }
sudo nft add rule nat postrouting oif eth0 ip saddr 10.0.0.0/24 masquerade
```

## Managing Rulesets

nftables rules are stored in files, usually under `/etc/nftables/`:

```bash
# Edit the main config
sudo nano /etc/nftables.conf

# Load a ruleset
sudo nft -f /etc/nftables.conf

# Save current ruleset
sudo nft list ruleset > /etc/nftables.conf

# Flush all rules
sudo nft flush ruleset
```

## Common nftables Commands

| Command | What it does |
|---------|-------------|
| `sudo nft list ruleset` | Show all rules |
| `sudo nft list table inet filter` | Show one table |
| `sudo nft add table inet NAME` | Create a table |
| `sudo nft delete table inet NAME` | Delete a table |
| `sudo nft add chain inet TABLE CHAIN` | Create a chain |
| `sudo nft add rule inet TABLE CHAIN RULE` | Add a rule |
| `sudo nft insert rule inet TABLE CHAIN RULE` | Insert at top |
| `sudo nft delete rule inet TABLE CHAIN HANDLE` | Delete by handle |
| `sudo nft -f FILE` | Load ruleset from file |
| `sudo nft flush ruleset` | Remove all rules |

Handles (for deleting specific rules):

```bash
# List rules with handles
sudo nft -a list table inet filter

# Delete by handle
sudo nft delete rule inet filter input handle 3
```

## Migration from iptables to nftables

### Step 1: Check if you're already using nftables

```bash
# If these return "nftables", iptables commands are translated
sudo iptables --version
# Output: iptables v1.8.7 (nf_tables)
```

### Step 2: Convert existing rules

```bash
# Dump iptables rules in nftables format
sudo iptables-save | sudo iptables-restore-translate -f -

# Or convert a saved file
sudo iptables-save > rules.txt
sudo iptables-restore-translate -f rules.txt > rules.nft
```

### Step 3: Test and apply

```bash
# Apply nftables rules
sudo nft -f rules.nft

# Verify
sudo nft list ruleset
```

### Step 4: Switch default backend (if needed)

On systems using the iptables compatibility layer, switch to native nftables:

```bash
# Debian/Ubuntu
sudo update-alternatives --set iptables /usr/sbin/iptables-nft

# Fedora/RHEL — nftables is already the default
```

## When to Use Which

| Situation | Recommendation |
|-----------|---------------|
| New deployment, modern distro | Use **nftables** (native, future-proof) |
| Existing iptables scripts | Keep **iptables** syntax (compatibility works) |
| Learning firewall concepts | Use **iptables** syntax (more documentation, simpler commands) |
| Complex rulesets | Use **nftables** (sets, maps, atomic updates) |
| You need ipset | Use **nftables** (built-in sets, no separate tool) |
| Legacy documentation/playbooks | Use **iptables** syntax (it still works) |
