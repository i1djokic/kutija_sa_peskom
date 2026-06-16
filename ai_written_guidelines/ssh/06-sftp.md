# sftp

Interactive file transfer protocol over SSH. Unlike `scp` (one-shot) and `rsync` (batch sync), SFTP lets you browse, upload, download, and manage files interactively.

## Connecting

```bash
sftp user@hostname
sftp -P 2222 user@hostname            # Non-default port (note: capital -P, unlike ssh)
sftp -i ~/.ssh/mykey user@hostname    # Specific key
sftp myserver                         # Uses Host config from ~/.ssh/config
```

## Interactive Commands

Once connected, you get an `sftp>` prompt:

```bash
help                    # List all commands
quit / exit             # Disconnect
```

### Navigation

```bash
pwd                     # Print remote working directory
lpwd                    # Print local working directory
ls                      # List remote files
lls                     # List local files
cd /remote/path         # Change remote directory
lcd ./local             # Change local directory
```

### Transfer Files

```bash
get file.txt                    # Download file to current local dir
get file.txt local-copy.txt     # Download and save with a different name
get -r ./remote-folder          # Download directory recursively
get -P file.txt                 # Download with progress (preserve timestamp)

put file.txt                    # Upload file to current remote dir
put file.txt /remote/path/      # Upload to a specific remote path
put -r ./local-folder           # Upload directory recursively
```

### Manage Remote Files

```bash
mkdir new-folder                # Create remote directory
rm file.txt                     # Delete remote file
rmdir folder                    # Delete remote directory (must be empty)
rename old.txt new.txt          # Rename remote file
chmod 755 script.sh             # Change remote file permissions
chown user:group file.txt       # Change remote owner (if you have permission)
ln -s /path/target linkname     # Create remote symlink
df -h                           # Show remote disk usage
```

## Batch Mode (Scripting)

Run SFTP commands non-interactively from a file or stdin:

```bash
# From a batch file
echo "get /remote/logs/app.log" > commands.txt
echo "bye" >> commands.txt
sftp -b commands.txt user@hostname

# From stdin
echo "get /remote/file.txt" | sftp -b - user@hostname
```

## One-Shot Download/Upload (No Interactive Session)

```bash
# Like scp, but using the SFTP protocol
sftp user@hostname:/remote/file.txt ./local/
```

## When to Use Which

| Tool | Best for |
|------|----------|
| [scp](./04-scp.md) | Quick one-off file copies |
| [rsync](./05-rsync.md) | Large transfers, backups, incremental sync, resuming |
| sftp | Interactive browsing, managing remote files, scripting transfers |
