# Runtime vs Permanent

Firewalld's two-configuration model is one of its defining features — and a common source of confusion.

## The Two Layers

| Layer | Where it's stored | Affects | Survives reboot | Survives `--reload` |
|-------|-------------------|---------|-----------------|---------------------|
| **Runtime** | In memory (kernel) | Current session | No | No |
| **Permanent** | `/etc/firewalld/` (XML files) | Next reload or reboot | Yes | Yes |

## How It Works

When you run a command **without** `--permanent`:

```bash
sudo firewall-cmd --add-service=http
# This adds http to the runtime config only.
# It works NOW but disappears after --reload or reboot.
```

When you run a command **with** `--permanent`:

```bash
sudo firewall-cmd --permanent --add-service=http
# This writes to the XML config file.
# It does NOT take effect until you reload or reboot.
```

To apply permanent changes without a full reload, use:

```bash
sudo firewall-cmd --runtime-to-permanent
# Copies current runtime config to permanent files.
```

## Reload Behavior

```bash
sudo firewall-cmd --reload
```

This **preserves** permanent config and **drops** runtime-only changes (except for established connections, which are kept).

```bash
sudo firewall-cmd --complete-reload
```

This **drops all** runtime state, including established connections. Use with care.

## Common Workflow Patterns

### Pattern 1: Test then Commit

```bash
# 1. Add runtime rules and test
sudo firewall-cmd --add-service=http
sudo firewall-cmd --add-service=https

# 2. Verify it works (test your application)
curl https://myserver/

# 3. Make permanent
sudo firewall-cmd --runtime-to-permanent
```

### Pattern 2: Always Permanent + Reload

```bash
# 1. Add permanently
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https

# 2. Apply
sudo firewall-cmd --reload
```

### Pattern 3: Permanent Only, Apply Later

```bash
# Write permanent config during maintenance window
sudo firewall-cmd --permanent --zone=public --add-source=10.0.0.0/24

# ... hours later ...
sudo firewall-cmd --reload
```

## Checking the Difference

```bash
# What's active right now (runtime)
sudo firewall-cmd --zone=public --list-all

# What's in the permanent config
sudo firewall-cmd --permanent --zone=public --list-all
```

## Direct Config File Access

Permanent config is stored in XML under `/etc/firewalld/`:

```
/etc/firewalld/
├── firewalld.conf        # Daemon configuration
├── lockdown-whitelist.xml # Lockdown whitelist
├── zones/                # Zone definitions
│   ├── public.xml
│   ├── internal.xml
│   └── ...
├── services/             # Custom service definitions
│   └── myapp.xml
├── icmptypes/            # ICMP type definitions
└── ipsets/               # IP set definitions
```

You can edit these files directly, then reload:

```bash
sudo firewall-cmd --reload
```

## Panic Mode

Panic mode drops **all** incoming and outgoing traffic. Use only in emergencies:

```bash
# Enable panic mode (drops everything)
sudo firewall-cmd --panic-on

# Check if panic mode is on
sudo firewall-cmd --query-panic

# Disable panic mode
sudo firewall-cmd --panic-off
```

Panic mode overrides all zone/rule configuration and is runtime-only.
