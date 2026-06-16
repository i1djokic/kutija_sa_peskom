# Linux Basics Learning Guide

A hands-on guide to learning Linux commands and system administration using your virtual machine.

## Table of Contents
1. [Getting Started](#getting-started)
2. [Linux File System](#linux-file-system)
3. [Basic Commands](#basic-commands)
4. [File Operations](#file-operations)
5. [Permissions & Users](#permissions--users)
6. [Process Management](#process-management)
7. [Networking](#networking)
8. [Package Management](#package-management)
9. [Text Editors](#text-editors)
10. [Bash Scripting Basics](#bash-scripting-basics)
11. [Practice Exercises](#practice-exercises)
12. [Learning Path](#learning-path)

---

## Getting Started

### Connect to Your VM

```bash
cd /path/to/simplevm
vagrant up --provider=libvirt
vagrant ssh
```

You're now inside your Linux VM! The prompt will look something like: `vagrant@linux-learning:~$`

### Know Your System

```bash
# What OS is this?
cat /etc/os-release

# What's the kernel version?
uname -a

# Who am I?
whoami

# Where am I?
pwd   # Print Working Directory

# What's my home directory content?
ls -la
```

---

## Linux File System

### Directory Structure

```
/           # Root directory (everything starts here)
├── home/   # User home directories
│   └── vagrant/   # Your home directory (~)
├── etc/    # Configuration files
├── var/    # Variable data (logs, etc.)
├── tmp/    # Temporary files
├── usr/    # User programs and data
├── bin/    # Essential command binaries
├── sbin/   # System binaries
└── dev/    # Device files
```

### Practice Navigation

```bash
# Start at root
cd /
pwd

# List files (try these options)
ls          # Simple list
ls -l        # Long format (permissions, size, date)
ls -la       # All files (including hidden)
ls -lh       # Human-readable sizes

# Navigate around
cd /home
cd /etc
cd ~         # Go home
cd ..        # Go up one level
cd -         # Go to previous directory

# Tip: Press TAB for autocompletion!
```

---

## Basic Commands

### System Information

```bash
# Date and time
date

# Calendar
cal

# How long has the system been running?
uptime

# System info
hostnamectl

# Disk usage
df -h        # Human-readable disk space
du -sh *     # Size of files/dirs in current directory

# Memory usage
free -h
```

### Help System

```bash
# Three ways to get help:
ls --help           # Quick help (most commands)
man ls              # Manual pages (detailed)
info ls             # Info documents (less common)

# Press 'q' to quit man/info pages
# Press '/' to search in man pages
```

---

## File Operations

### Creating and Managing Files

```bash
# Create empty file
touch file1.txt
touch file2.txt file3.txt

# Create directory
mkdir myfolder
mkdir -p path/to/nested/folder  # Create parent dirs if needed

# Copy files
cp file1.txt file1_copy.txt
cp -r myfolder myfolder_backup   # -r = recursive (for directories)

# Move/rename files
mv file2.txt file2_renamed.txt   # Rename
mv file3.txt myfolder/            # Move to directory

# Delete files
rm file1_copy.txt
rm -r myfolder_backup            # Remove directory recursively
rm -f file.txt                   # Force delete (no confirmation)

# ⚠️ WARNING: rm -rf / can delete everything! Be careful!
```

### Viewing File Content

```bash
# Create a test file with content
echo "Hello World" > test.txt
echo "Second line" >> test.txt     # >> appends, > overwrites

# View file contents (try each):
cat test.txt          # Show entire file
less test.txt        # Scrollable view (press 'q' to quit)
head test.txt        # First 10 lines
tail test.txt        # Last 10 lines
tail -f /var/log/syslog  # Follow log file (Ctrl+C to stop)
```

### Finding Files

```bash
# Find files by name
find /home -name "*.txt"
find /etc -name "passwd"

# Find files by type
find . -type f      # Files only
find . -type d      # Directories only

# Quick search (faster than find)
locate file.txt      # Requires: sudo apt install mlocate

# Search inside files
grep "hello" test.txt
grep -r "error" /var/log/   # Recursive search in directory
```

---

## Permissions & Users

### Understanding Permissions

Linux permissions have three categories:
- **r** (read) = 4
- **w** (write) = 2
- **x** (execute) = 1

```
-rwxr-xr--  1 vagrant vagrant  1234 Jan 1 10:00 script.sh
│││││││││
│││││││└└─ Other users: read only (4)
│││││└└── Group: read + execute (5 = 4+1)
│││└└── Owner (vagrant): read + write + execute (7 = 4+2+1)
││└── Hard link count
│└── Owner & Group
└── File type (- = file, d = directory)
```

### Working with Permissions

```bash
# Create a test file
touch script.sh
echo "echo Hello" > script.sh

# Check permissions
ls -l script.sh

# Change permissions
chmod u+x script.sh      # Add execute for user (owner)
chmod g+r script.sh      # Add read for group
chmod o-r script.sh      # Remove read for others

# Numeric method (easier!)
chmod 755 script.sh      # rwxr-xr-x (common for scripts)
chmod 644 script.sh      # rw-r--r-- (common for files)
chmod 700 script.sh      # rwx------ (private file)

# Change owner
sudo chown root:root script.sh  # Change owner and group
sudo chown vagrant:vagrant script.sh  # Change back
```

### User Management

```bash
# Who am I?
whoami

# Who's logged in?
who
w                       # More detailed

# Switch user
su - username           # Switch to user (need password)
sudo su -               # Switch to root (if you have sudo access)

# Add user (requires sudo)
sudo useradd -m newuser    # Create user with home directory
sudo passwd newuser       # Set password
sudo usermod -aG sudo newuser  # Add to sudo group

# Delete user
sudo userdel -r newuser    # -r removes home directory
```

---

## Process Management

### Viewing Processes

```bash
# List processes
ps                        # Current shell processes
ps aux                    # All processes
ps aux | grep python      # Search for specific process

# Real-time process viewer
top                       # Press 'q' to quit
htop                      # Better version (install: sudo apt install htop)

# Find process by name
pgrep bash
pidof bash
```

### Controlling Processes

```bash
# Start a background process
sleep 100 &               # & runs in background
jobs                      # List background jobs

# Kill a process
kill PID                  # Graceful kill
kill -9 PID              # Force kill

# Kill by name
pkill process_name
killall process_name

# Nice values (priority, -20 to 19, lower = higher priority)
nice -n 10 command       # Start with lower priority
renice +5 PID            # Change priority of running process
```

---

## Networking

### Network Configuration

```bash
# Network interfaces
ip addr                   # Show IP addresses (modern)
ip link                   # Show interfaces

# Test connectivity
ping -c 4 google.com    # Ping 4 times
ping -c 4 8.8.8.8      # Ping by IP

# DNS lookup
nslookup google.com
dig google.com            # Better version (install: sudo apt install dnsutils)

# Network statistics
ss -tlnp                  # Listening ports (modern)
netstat -tlnp            # Same (older)

# Download files
curl -O https://example.com/file.txt
wget https://example.com/file.txt
```

### SSH & Remote Access

```bash
# Connect to remote server (not needed in VM, but good to know)
ssh user@hostname
ssh -p 2222 user@hostname    # Custom port

# Copy files remotely
scp file.txt user@remote:/path/
scp -r folder/ user@remote:/path/

# SSH keys (more secure than passwords)
ssh-keygen                  # Generate key pair
ssh-copy-id user@remote    # Copy public key to remote
```

---

## Package Management

### Debian/Ubuntu (apt) - What Your VM Uses

```bash
# Update package list
sudo apt update

# Upgrade installed packages
sudo apt upgrade
sudo apt full-upgrade      # Also remove obsolete packages

# Search for packages
apt search nginx
apt show nginx             # Show package details

# Install packages
sudo apt install nginx
sudo apt install htop vim curl wget

# Remove packages
sudo apt remove nginx
sudo apt purge nginx       # Also remove config files
sudo apt autoremove        # Remove unused dependencies

# Clean up
sudo apt clean             # Clear package cache
```

### Common Software to Install

```bash
# System tools
sudo apt install htop tree ncdu

# Network tools
sudo apt install curl wget net-tools iputils-ping traceroute

# Text editors
sudo apt install vim nano emacs

# Development
sudo apt install build-essential git
```

---

## Text Editors

### Nano (Beginner-Friendly)

```bash
nano filename.txt
```

**Basic commands (displayed at bottom):**
- `Ctrl + O` - Save (Write Out)
- `Ctrl + X` - Exit
- `Ctrl + K` - Cut line
- `Ctrl + U` - Paste line
- `Ctrl + W` - Search
- `Ctrl + G` - Help

### Vim (Powerful, Steep Learning Curve)

```bash
vim filename.txt
```

**Basic Vim commands:**
- `i` - Enter Insert mode (start typing)
- `Esc` - Exit Insert mode
- `:w` - Save
- `:q` - Quit
- `:wq` - Save and quit
- `:q!` - Quit without saving
- `dd` - Delete line (in normal mode)
- `yy` - Copy line
- `p` - Paste

**Tip:** Start with nano, try vim later when comfortable.

---

## Bash Scripting Basics

### Your First Script

Create a file called `hello.sh`:

```bash
nano hello.sh
```

Add this content:

```bash
#!/bin/bash
# This is a comment

echo "Hello, World!"
echo "Today is: $(date)"
echo "Your home is: $HOME"
```

Save and run:

```bash
chmod +x hello.sh      # Make executable
./hello.sh             # Run it
```

### Variables and Input

```bash
#!/bin/bash

# Variables
name="Alice"
echo "Hello, $name!"

# User input
read -p "Enter your name: " user_name
echo "Hello, $user_name!"

# Arguments
echo "Script name: $0"
echo "First argument: $1"
echo "Second argument: $2"
echo "All arguments: $@"
echo "Number of arguments: $#"

# Run with: ./script.sh arg1 arg2
```

### Conditions

```bash
#!/bin/bash

# If statement
read -p "Enter a number: " num

if [ $num -gt 10 ]; then
    echo "Number is greater than 10"
elif [ $num -eq 10 ]; then
    echo "Number is exactly 10"
else
    echo "Number is less than 10"
fi

# String comparison
read -p "Enter yes or no: " answer
if [ "$answer" = "yes" ]; then
    echo "You said yes!"
fi

# File tests
if [ -f "file.txt" ]; then
    echo "file.txt exists and is a regular file"
fi

if [ -d "mydir" ]; then
    echo "mydir exists and is a directory"
fi
```

### Loops

```bash
#!/bin/bash

# For loop
for i in 1 2 3 4 5; do
    echo "Number: $i"
done

# For loop with range
for i in {1..5}; do
    echo "Count: $i"
done

# While loop
count=1
while [ $count -le 5 ]; do
    echo "While count: $count"
    ((count++))
done

# Loop through files
for file in *.txt; do
    echo "Found file: $file"
done
```

### Functions

```bash
#!/bin/bash

# Define function
greet() {
    echo "Hello, $1!"
    echo "Welcome to Linux!"
}

# Call function
greet "Alice"
greet "Bob"

# Function with return value
add() {
    result=$(($1 + $2))
    echo $result
}

sum=$(add 5 3)
echo "5 + 3 = $sum"
```

---

## Practice Exercises

### Beginner Level

**Exercise 1: Navigation Practice**
```bash
# Do this step by step:
cd /
ls
cd /home
ls -la
cd ~
pwd
cd /var/log
ls -lh
cd -
```

**Exercise 2: File Operations**
```bash
# Create this structure:
mkdir -p practice/{docs,images,backup}
cd practice
touch docs/file1.txt docs/file2.txt
echo "Hello" > docs/file1.txt
cp docs/file1.txt backup/
mv docs/file2.txt images/
ls -R    # Recursive listing
```

**Exercise 3: Permissions**
```bash
touch secret.txt
chmod 600 secret.txt      # Owner read/write only
ls -l secret.txt
chmod 644 secret.txt      # Restore normal permissions
```

### Intermediate Level

**Exercise 4: Process Management**
```bash
# Start a long process in background
sleep 300 &

# Check it's running
ps aux | grep sleep

# Kill it
pkill sleep
```

**Exercise 5: Text Processing**
```bash
# Create a sample file
cat > users.txt << EOF
Alice 25 Engineer
Bob 30 Designer
Charlie 28 Engineer
Diana 35 Manager
EOF

# Process it
cut -d' ' -f1 users.txt          # Get first column
grep "Engineer" users.txt         # Find engineers
sort users.txt                    # Sort lines
wc -l users.txt                  # Count lines
```

**Exercise 6: Simple Backup Script**
```bash
# Create backup.sh
nano backup.sh
```

```bash
#!/bin/bash
# Simple backup script

src_dir="$1"
backup_dir="$2"
date=$(date +%Y%m%d)

if [ -z "$src_dir" ] || [ -z "$backup_dir" ]; then
    echo "Usage: $0 <source_dir> <backup_dir>"
    exit 1
fi

mkdir -p "$backup_dir"
tar -czf "$backup_dir/backup_$date.tar.gz" "$src_dir"
echo "Backup created: $backup_dir/backup_$date.tar.gz"
```

```bash
chmod +x backup.sh
mkdir test_data
echo "test" > test_data/file.txt
./backup.sh test_data backups/
```

### Advanced Level

**Exercise 7: System Monitor Script**
Create a script that:
- Shows CPU usage
- Shows memory usage
- Shows disk usage
- Logs to a file with timestamp
- Runs in a loop every 5 seconds

**Exercise 8: Log Analyzer**
Create a script that:
- Takes a log file as argument
- Counts errors, warnings, info messages
- Shows top 5 most common errors
- Generates a report

---

## Learning Path

### Week 1: Basics
- [ ] Connect to VM and explore system info commands
- [ ] Practice file navigation (cd, ls, pwd)
- [ ] Practice file operations (touch, cp, mv, rm)
- [ ] Learn to use nano editor
- [ ] Understand file permissions (rwx, chmod)

### Week 2: Intermediate
- [ ] Process management (ps, top, kill)
- [ ] Basic networking (ip, ping, curl)
- [ ] Package management (apt update, install, remove)
- [ ] Try vim editor basics
- [ ] Learn to use grep, find, and pipes (|)

### Week 3: Scripting
- [ ] Write your first bash script
- [ ] Learn variables and user input
- [ ] Practice if statements and loops
- [ ] Create functions
- [ ] Build a useful script (backup, monitor, etc.)

### Week 4: System Administration
- [ ] User management (adduser, usermod)
- [ ] Service management (systemctl)
- [ ] Log files and log rotation
- [ ] Cron jobs (scheduled tasks)
- [ ] Basic security (firewall, SSH keys)

### Beyond: Advanced Topics
- [ ] Advanced bash scripting
- [ ] Regular expressions
- [ ] Sed and awk text processing
- [ ] Docker and containers
- [ ] Kubernetes (use the kubernetes/ folder project!)

---

## Quick Reference Card

```bash
# Files
ls, cd, pwd, touch, cp, mv, rm, mkdir, rmdir

# Viewing
cat, less, head, tail, grep

# Permissions
chmod, chown, chgrp

# Processes
ps, top, htop, kill, pkill, jobs, bg, fg

# Network
ip, ping, curl, wget, ssh, scp, netstat, ss

# Search
find, grep, locate, which, whereis

# Archives
tar, gzip, gunzip, zip, unzip

# System
df, du, free, uptime, uname, whoami, w

# Package (Debian)
apt update, apt install, apt remove, apt search
```

---

## Resources

### Online Practice
- **Linux Journey**: https://linuxjourney.com/ (interactive tutorials)
- **OverTheWire Bandit**: https://overthewire.org/wargames/bandit/ (game-based learning)
- **Codecademy**: https://www.codecademy.com/learn/learn-the-command-line

### Documentation
- **Debian Manual**: https://www.debian.org/doc/
- **Ubuntu Docs**: https://ubuntu.com/tutorials
- **Arch Wiki**: https://wiki.archlinux.org/ (great for all distros)

### Books
- "The Linux Command Line" by William Shotts (free online)
- "Linux Basics for Hackers" by OccupyTheWeb

### Cheat Sheets
- https://linuxcommand.org/lc3_learning_the_shell.php
- https://github.com/LeCoupa/awesome-cheatsheets

---

## Tips for Success

1. **Practice daily** - Even 15 minutes helps
2. **Break things** - You're in a VM, you can always reset!
3. **Read error messages** - They usually tell you what's wrong
4. **Use TAB completion** - Saves time and prevents typos
5. **Check `man` pages** - Built-in documentation
6. **Experiment** - Try different options with commands
7. **Take notes** - Keep a text file with commands you learn
8. **Join communities** - Reddit r/linux, LinuxQuestions.org

---

**Happy Learning! 🐧**

Run `vagrant ssh` and start with `ls -la` right now!
