# scp

Secure copy — simple, one-shot file transfers over SSH.

## Basic Usage

```bash
# Copy a file to a remote host
scp file.txt user@hostname:/remote/path/

# Copy from remote to local
scp user@hostname:/remote/file.txt ./local/

# Copy a directory recursively
scp -r ./myfolder user@hostname:/remote/path/

# Copy between two remote hosts (traffic goes through your machine)
scp user1@host1:/file.txt user2@host2:/file.txt
```

## Common Options

```bash
scp -i ~/.ssh/mykey file.txt user@hostname:/remote/   # Specific key
scp -P 2222 file.txt user@hostname:/remote/            # Specific port (capital -P)
scp -C file.txt user@hostname:/remote/                 # Enable compression
scp -p file.txt user@hostname:/remote/                 # Preserve timestamps
scp -v file.txt user@hostname:/remote/                 # Verbose (debug)
```

## From Config

If you have a Host block in `~/.ssh/config`, use the alias:

```bash
scp file.txt myserver:/remote/path/
```

## When to Use scp

- Quick one-off file copies
- Simple transfers without complex rules
- Scripting with minimal dependencies

For larger or repeated transfers, consider [rsync](./05-rsync.md) instead.
