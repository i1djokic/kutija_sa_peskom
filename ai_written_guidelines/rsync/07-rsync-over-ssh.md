# Rsync Over SSH

Rsync uses SSH by default for remote transfers. Here's how to configure it for non-standard setups.

## Custom SSH Port

```bash
# Specify port with -e
rsync -avz -e "ssh -p 2222" ./local/ user@host:/remote/

# Using the SSH config file (~/.ssh/config) is cleaner:
# Add to ~/.ssh/config:
#   Host myserver
#       HostName host.example.com
#       Port 2222
#
# Then just:
rsync -avz ./local/ myserver:/remote/
```

## Specific SSH Key

```bash
rsync -avz -e "ssh -i ~/.ssh/mykey" ./local/ user@host:/remote/
```

## Combining Multiple SSH Options

```bash
rsync -avz -e "ssh -p 2222 -i ~/.ssh/mykey -o ServerAliveInterval=30" \
    ./local/ user@host:/remote/
```

## Using a Jump Host (Bastion)

```bash
# Via ProxyJump (SSH 7.3+)
rsync -avz -e "ssh -J bastion.example.com" ./local/ user@internal:/remote/

# Simpler: define in ~/.ssh/config
# Host internal
#     HostName 10.0.1.50
#     User user
#     ProxyJump bastion.example.com
#
# Then just:
rsync -avz ./local/ internal:/remote/
```

## Changing the Remote Shell

By default rsync uses SSH. You can use any remote shell:

```bash
# Explicit SSH (default, same as omitting -e)
rsync -avz -e ssh ./local/ user@host:/remote/

# With rsync daemon (rsync:// protocol)
rsync -avz rsync://host/module/path/ /local/
```

## Forcing rsync to Use SSH (not the rsync daemon)

```bash
# When the remote path contains a colon, rsync assumes SSH
rsync -avz file.txt user@host:/path/      # SSH (has :)

# Colon after hostname = SSH, double colon = rsync daemon
rsync -avz file.txt user@host::module/    # rsync daemon (has ::)
rsync -avz file.txt host:/path/           # SSH (has colon)
rsync -avz file.txt host::module/         # rsync daemon (double colon)
```

## Sparse Files

For files with large empty sections (VM images, database files):

```bash
rsync -avz --sparse ./local/ user@host:/remote/
```

## Over a Slow or Unstable Connection

```bash
# Compress, resume, keep alive
rsync -avzP \
    -e "ssh -o ServerAliveInterval=15 -o ServerAliveCountMax=3" \
    ./local/ user@host:/remote/
```

## SSH Config Example

```sshconfig
# ~/.ssh/config for rsync
Host backups
    HostName backup.example.com
    User rsync-user
    Port 2222
    IdentityFile ~/.ssh/backup-key
    ServerAliveInterval 30
```

Now you can rsync with just:

```bash
rsync -avz ./data/ backups:/storage/data/
```
