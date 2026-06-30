# Bash Scripting — DevOps Cheatsheet

## Special Variables

| Var | Meaning |
|-----|---------|
| `$0` | script name |
| `$1`-`$9` | positional args |
| `$#` | arg count |
| `$?` | last exit code |
| `$@` / `$*` | all args |
| `$$` | PID |
| `$!` | last bg PID |

## Conditionals

```bash
[[ -f "$file" ]] && echo "file exists"
[[ -d "$dir" ]]  && echo "is dir"
[[ -z "$var" ]]  && echo "empty"
[[ -n "$var" ]]  && echo "not empty"
[[ $a -eq $b ]]  # -ne -lt -gt -le -ge
[[ $a == $b ]]   # string compare
[[ $a =~ ^re ]]  # regex match
```

## Loops

```bash
for f in *; do echo "$f"; done
for i in {1..10}; do echo "$i"; done
while IFS= read -r line; do ...; done < file
until condition; do ...; done
```

## Arrays

```bash
arr=("a" "b" "c")
echo "${arr[0]}"       # first
echo "${#arr[@]}"      # length
echo "${arr[@]}"       # all
echo "${!arr[@]}"      # indices
```

## Parameter Expansion

```bash
${var:-default}       # default if unset
${var:=default}       # assign default if unset
${var:?error}         # die if unset
${var:+alt}           # alt if set
${var#prefix}         # remove prefix (short)
${var##prefix}        # remove prefix (long)
${var%suffix}         # remove suffix (short)
${var%%suffix}        # remove suffix (long)
${var/old/new}        # replace first
${var//old/new}       # replace all
${var:offset:len}     # substring
${#var}               # length
```

## Error Handling

```bash
set -euo pipefail
trap 'echo "err at line $LINENO"; exit 1' ERR
cmd || exit 1
cmd || { echo "failed"; exit 1; }
${VAR:?unset}
```

## Process Substitution

```bash
diff <(cmd1) <(cmd2)
while read -r line; do ...; done < <(cmd)
```

## getopts

```bash
while getopts "ab:o:" o; do
  case $o in
    a) a=1;;
    b) b=$OPTARG;;
    o) out=$OPTARG;;
    *) exit 1;;
  esac
done
shift $((OPTIND-1))
```

## Functions

```bash
myfunc() { local arg="$1"; echo "$arg"; }
```

## One-liners

```bash
grep -rl pattern | xargs sed -i 's/old/new/g'
find . -name "*.log" -mtime +7 -delete
curl -s url | jq '.key'
watch -n 1 'cmd'
ps aux --sort=-%mem | head
```
