# Text Processing

## grep — Search Text

```bash
# Basic
grep "error" /var/log/syslog
grep -i "warning" /var/log/syslog       # case-insensitive
grep -r "TODO" src/                      # recursive
grep -l "config" /etc/*.conf            # list filenames only
grep -c "failed" auth.log               # count matches
grep -v "^#" /etc/ssh/sshd_config       # invert match (strip comments)
grep -A2 -B2 "panic" log.txt            # context lines
grep -E "ERROR|CRITICAL" log.txt        # extended regex
grep -F "literally.*dots" file.txt      # fixed string (no regex)

# Print lines around match with line numbers
grep -n "listen" nginx.conf

# Multiple patterns from file
grep -f patterns.txt data.txt
```

## sed — Stream Editor

```bash
# Substitute (first per line)
sed 's/old/new/' file.txt
sed 's/old/new/g' file.txt             # all occurrences
sed 's/old/new/gi' file.txt            # case-insensitive
sed 's/old/new/' file.txt > new.txt    # write to new file
sed -i.bak 's/old/new/g' file.txt      # in-place (with backup)

# Line-specific
sed '2s/old/new/' file.txt             # line 2 only
sed '1,5s/old/new/g' file.txt          # lines 1-5

# Delete lines
sed '/^#/d' /etc/ssh/sshd_config       # delete comments
sed '/^$/d' file.txt                   # delete empty lines
sed '5d' file.txt                      # delete line 5

# Print specific lines
sed -n '10,20p' file.txt               # lines 10-20
sed -n '/error/p' log.txt              # only matching lines

# In-place edit (common DevOps pattern)
sed -i 's/Listen 80/Listen 8080/' /etc/apache2/ports.conf
```

## awk — Pattern Scanning & Processing

```bash
# Column extraction
awk '{print $1, $3}' /var/log/syslog   # first and third fields
awk -F: '{print $1}' /etc/passwd       # field separator

# Filter
awk '$3 > 50 {print $1, $3}' data.txt  # conditional
awk '/ERROR/ {print $1, $2, $NF}' log.txt

# Built-in variables
awk '{print NR, $0}' file.txt          # line numbers
awk '{print NF}' file.txt              # number of fields per line

# Common patterns
df / | awk 'NR==2 {print $5}'          # disk usage % (strip header)
ps aux | awk '$3 > 10 {print $2}'      # PIDs with CPU > 10%
awk '!seen[$0]++' file.txt             # deduplicate lines
```

## cut — Column Extraction

```bash
cut -d: -f1 /etc/passwd               # first field, colon-delimited
cut -d: -f1,3 /etc/passwd             # first and third fields
cut -c1-10 file.txt                   # first 10 characters per line
cut -f2- /etc/hosts                   # skip first whitespace field
```

## sort — Order Lines

```bash
sort file.txt                          # alphabetical
sort -n numbers.txt                    # numeric
sort -r file.txt                       # reverse
sort -k2 data.tsv                      # sort by column 2
sort -t: -k3 -n /etc/passwd           # sort by UID (numeric, colon sep)
sort -u file.txt                       # sort and deduplicate
```

## uniq — Unique Lines (usually after sort)

```bash
sort log.txt | uniq                    # unique lines
sort log.txt | uniq -c                 # count occurrences
sort log.txt | uniq -d                 # only duplicates
sort log.txt | uniq -u                 # only unique lines
```

## Combining — Pipeline Workflow

```bash
# Top 10 IPs from access log
awk '{print $1}' access.log | sort | uniq -c | sort -rn | head -10

# Count error codes by hour
awk '{print $4, $9}' access.log | sed 's/\[//;s/:.*//' | sort | uniq -c

# Parse structured data
cat /etc/hosts | awk '!/^#/' | while read -r ip host; do
    echo "$host -> $ip"
done
```
