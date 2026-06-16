# Key Management

Using SSH keys is more secure and convenient than password authentication.

## Generating a Key Pair

```bash
# Modern and recommended (Ed25519)
ssh-keygen -t ed25519 -C "your@email.com"

# Fallback (RSA, for older servers)
ssh-keygen -t rsa -b 4096 -C "your@email.com"
```

The `-C` flag adds a comment (usually your email) to help identify the key.

You'll be prompted for:
- **Save location** — default: `~/.ssh/id_ed25519` (private) and `~/.ssh/id_ed25519.pub` (public)
- **Passphrase** — strongly recommended; protects the key if stolen

## Key Types

| Type | Security | Compatibility | When to use |
|------|----------|---------------|-------------|
| Ed25519 | Excellent | Good (OpenSSH 6.5+) | Default for modern systems |
| RSA 4096 | Good | Excellent (all servers) | Legacy/older systems |
| ECDSA | Good | Good | Less common, avoid |
| DSA | Poor | Limited | Deprecated, do not use |

## The Public vs Private Key

- **Private key** (`id_ed25519`) — keep secret, never share, set `600` permissions
- **Public key** (`id_ed25519.pub`) — safe to share; copy to servers you connect to

## Copying the Public Key to a Server

```bash
# Automatic (if ssh-copy-id is available)
ssh-copy-id user@hostname
ssh-copy-id -i ~/.ssh/mykey.pub user@hostname  # Specific key

# Manual
cat ~/.ssh/id_ed25519.pub | ssh user@hostname "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

## ssh-agent

The SSH agent holds your decrypted private keys in memory so you don't have to type your passphrase repeatedly.

```bash
# Start the agent (usually auto-started on macOS/desktop Linux)
eval "$(ssh-agent -s)"

# Add a key
ssh-add ~/.ssh/id_ed25519

# Add with a specific lifetime (5 hours)
ssh-add -t 5h ~/.ssh/id_ed25519

# List loaded keys
ssh-add -l

# Remove all keys
ssh-add -D
```

## Checking Key Fingerprint

```bash
# Get the fingerprint of your key
ssh-keygen -lf ~/.ssh/id_ed25519.pub

# Get the fingerprint in SSH format (matches what the server shows on first connect)
ssh-keygen -lf ~/.ssh/id_ed25519.pub -E md5
```
