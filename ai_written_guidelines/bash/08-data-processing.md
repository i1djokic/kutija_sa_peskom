# Data Processing

## JSON with `jq`

```bash
# Parse JSON from file or stdin
cat data.json | jq '.'                    # pretty-print
jq '.name' data.json                     # extract key
jq '.users[]' data.json                  # iterate array
jq '.users[] | select(.role == "admin")'  # filter
jq '.users | length' data.json           # count
jq -r '.name' data.json                  # raw output (no quotes)

# Common DevOps patterns
jq '.instances[] | {id: .id, ip: .ip}' infra.json
jq 'group_by(.status) | {key: .[0].status, count: length}' issues.json

# Update JSON in place
jq '.version = "2.0.0"' package.json > package.json.tmp
mv package.json.tmp package.json         # jq has no -i flag

# Merge files
jq -s '.[0] * .[1]' defaults.json overrides.json
```

## YAML with `yq`

```bash
# yq is the YAML equivalent of jq (https://github.com/mikefarah/yq)

# Read value
yq '.services.web.image' docker-compose.yml

# Update
yq -i '.services.web.ports += "8080:80"' docker-compose.yml

# Merge
yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' a.yml b.yml
```

## CSV Parsing (Pure Bash)

```bash
# Simple — no quoted commas
while IFS=',' read -r col1 col2 col3; do
    echo "col1=$col1 col2=$col2 col3=$col3"
done < data.csv

# Skip header
{
    read -r header
    while IFS=',' read -r col1 rest; do
        echo "$col1"
    done
} < data.csv

# For real CSV with escaping, use a tool like csvkit or miller
# mlr --csv cut -f name,email data.csv
# csvcut -c name,email data.csv
```

## INI / Config Files

```bash
# Simple key=value parser
parse_env() {
    local file="$1"
    while IFS='=' read -r key value; do
        [[ -z "$key" || "$key" =~ ^# ]] && continue
        key="${key// /}"
        value="${value//\"/}"
        printf -v "$key" "%s" "$value"
    done < "$file"
}

# Usage
parse_env /etc/myapp.conf
echo "$DB_HOST"
```

## Parsing /etc/os-release

```bash
# Source directly into environment
source /etc/os-release
echo "$ID"        # ubuntu, debian, etc.
echo "$VERSION_ID" # 22.04, 12, etc.

# Safe way (no unexpected vars leaking)
os_info=$(grep -E '^(ID|VERSION_ID)=' /etc/os-release)
eval "$os_info"
```
