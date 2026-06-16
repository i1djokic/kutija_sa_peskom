# Subprocess & System Automation

## Running Commands

```bash
# Check exit code without capturing output
if cmd; then echo "OK"; fi

# Capture output
output=$(cmd)
output=$(cmd 2>&1)       # capture stderr too

# Discard output
cmd >/dev/null 2>&1
cmd &>/dev/null          # bash 4.0+ shorthand

# Timeout
timeout 10 cmd || echo "Command timed out or failed"

# Run in background
cmd &
pid=$!
wait "$pid"
echo "Exit code: $?"
```

## Process Management

```bash
# Find PID by name
pgrep -f "python.*server"      # list PIDs matching pattern
pgrep -x nginx                 # exact match
pidof nginx                    # legacy, exact binary name

# Kill by name
pkill -f "stale-process"
pkill -9 -x runaway            # SIGKILL exact match

# Check if process is running
if pgrep -x nginx &>/dev/null; then
    echo "nginx is running"
fi

# Graceful shutdown
kill -TERM "$pid"              # SIGTERM (default)
sleep 5
kill -0 "$pid" 2>/dev/null && kill -KILL "$pid"  # SIGKILL if still alive
```

## Linux Process Tree

```bash
# Parent/child relationships
ps auxf                      # forest view
pstree                       # clean tree view (install psmisc)
ps --ppid "$pid"             # children of a process

# Zombie detection
ps aux | awk '$8 ~ /Z/ {print "ZOMBIE:", $2, $11}'
```

## File Descriptors & Redirection

```bash
# Standard redirections
cmd > file          # stdout to file
cmd >> file         # append stdout
cmd 2> file         # stderr to file
cmd &> file         # both to file (bash 4+)
cmd > file 2>&1     # both (POSIX)
cmd 2>&1 | grep x   # pipe both

# Here-doc to stdin
cmd <<< "$variable"           # string as stdin
cmd <<< "inline string"       # literal string

# File descriptors
exec 3< /etc/hosts            # open for reading
cat <&3
exec 3<&-                    # close

exec 4> /tmp/output.txt       # open for writing
echo "log" >&4
exec 4>&-
```

## daemon / service Management

```bash
# systemd (modern Linux)
systemctl start nginx
systemctl stop nginx
systemctl restart nginx
systemctl reload nginx         # config reload (no downtime)
systemctl enable nginx         # start on boot
systemctl status nginx
systemctl is-active --quiet nginx  # exit 0 if running
systemctl is-enabled --quiet nginx # exit 0 if enabled

# Check failed services
systemctl --failed
```

## Resource Limits

```bash
# ulimit — shell resource limits
ulimit -n                    # open file descriptor limit
ulimit -u                    # max user processes
ulimit -s                    # stack size

# Raise limits (in script)
ulimit -n 65536              # more file descriptors

# Check system limits
cat /proc/sys/fs/file-max   # system-wide fd limit
cat /proc/sys/kernel/pid_max
```
