# Bash Basics

## Shebang & Script Header

```bash
#!/bin/bash
# Always use /bin/bash (not /bin/sh) for full feature set
```

## Variables

```bash
# Assignment (no spaces around =)
name="Alice"
count=42

# Usage — always quote
echo "$name"
echo "${count}"

# Default values
echo "${VAR:-default}"    # Use default if unset
echo "${VAR:=default}"    # Assign default if unset
echo "${VAR:?error msg}"  # Error if unset
echo "${VAR:+alt}"        # Use alt if set

# Indirection
varname="count"
echo "${!varname}"        # 42
```

## Arrays

```bash
# Indexed
fruits=("apple" "banana" "cherry")
echo "${fruits[0]}"       # apple
echo "${#fruits[@]}"      # length
echo "${fruits[@]}"       # all elements

# Associative (declare -A)
declare -A services
services[web]="nginx"
services[db]="postgres"
echo "${services[web]}"   # nginx
```

## Control Flow

```bash
# if / elif / else
if [[ "$USER" == "root" ]]; then
    echo "Running as root"
elif [[ -f /etc/debian_version ]]; then
    echo "Debian-based"
else
    echo "Other"
fi

# File tests
[[ -f "$file" ]]    # exists and is file
[[ -d "$dir" ]]     # exists and is directory
[[ -x "$bin" ]]     # executable
[[ -z "$str" ]]     # empty string
[[ -n "$str" ]]     # non-empty string

# Pattern matching
[[ "$name" == *.txt ]]    # glob match
[[ "$name" =~ ^[A-Z] ]]  # regex match

# Loop constructs
for i in {1..5}; do echo "$i"; done

for file in /etc/*.conf; do
    echo "$file"
done

while IFS= read -r line; do
    echo "$line"
done < /var/log/syslog

until ping -c1 host &>/dev/null; do
    sleep 1
done
```

## Case Statement

```bash
case "$1" in
    start)   systemctl start "$2" ;;
    stop)    systemctl stop "$2"  ;;
    restart) systemctl restart "$2" ;;
    *)       echo "Usage: $0 {start|stop|restart} service" ;;
esac
```

## Globbing

```bash
ls *.log                    # all .log files
ls file[0-9].txt            # file0-file9
ls {a,b,c}.conf            # a.conf b.conf c.conf
ls **/*.yaml                # recursive (shopt -s globstar)
shopt -s nullglob           # empty glob = nothing (not literal *)
shopt -s dotglob            # match hidden files
```

## Arithmetic

```bash
# Integer math
echo $(( 10 + 2 * 3 ))     # 16
(( count++ ))
(( total = price * quantity ))

# bc for floats
echo "scale=2; 10 / 3" | bc   # 3.33
```

## Here-Documents

```bash
# With variable expansion
cat > /etc/myapp.conf << EOF
host = $HOSTNAME
port = ${PORT:-8080}
EOF

# Without expansion (quote delimiter)
cat > /etc/myapp.conf << 'EOF'
literal $HOME /etc/default
EOF
```
