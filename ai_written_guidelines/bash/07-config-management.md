# Configuration Management

## .env Files

```bash
# .env format: KEY=VALUE (no spaces around =)
# DB_HOST=localhost
# DB_PORT=5432

# Load .env safely (without eval)
load_env() {
    local file="${1:-.env}"
    [[ -f "$file" ]] || return
    while IFS='=' read -r key value; do
        [[ -z "$key" || "$key" =~ ^# ]] && continue
        key="${key// /}"
        value="${value%\"*}"
        value="${value#\"*}"
        export "$key=$value"
    done < "$file"
}

# Usage
load_env /etc/myapp/.env
echo "$DB_HOST"
```

## Config Layering (Default + Override)

```bash
# 1. Built-in defaults
PORT=${PORT:-8080}
HOST=${HOST:-0.0.0.0}
LOG_LEVEL=${LOG_LEVEL:-info}

# 2. Config file overrides (if exists)
config_file="/etc/myapp/config.sh"
[[ -f "$config_file" ]] && source "$config_file"

# 3. Environment variable overrides (highest priority)
# Already handled by reading env vars first

# Usage
echo "Starting on $HOST:$PORT (log level: $LOG_LEVEL)"
```

## Config Validation

```bash
validate_config() {
    local errors=0

    [[ -z "${DB_HOST:-}" ]] && { echo "DB_HOST not set"; ((errors++)); }
    [[ -z "${DB_PASSWORD:-}" ]] && { echo "DB_PASSWORD not set"; ((errors++)); }
    [[ "${PORT:-}" -lt 1 || "${PORT:-}" -gt 65535 ]] && { echo "Invalid PORT"; ((errors++)); }

    return "$errors"
}

if ! validate_config; then
    echo "Configuration errors found" >&2
    exit 1
fi
```

## Config Templating with envsubst

```bash
# Template file (config.tmpl)
# server {
#     listen ${NGINX_PORT};
#     server_name ${SERVER_NAME};
# }

# Generate config
export NGINX_PORT=8080 SERVER_NAME=example.com
envsubst < config.tmpl > /etc/nginx/sites-available/default

# Selective substitution (only specific vars)
envsubst '${NGINX_PORT} ${SERVER_NAME}' < config.tmpl > /etc/nginx/conf.d/app.conf
```

## YAML Frontmatter Parsing

```bash
# Extract YAML frontmatter from markdown/docs
parse_frontmatter() {
    local file="$1"
    awk 'BEGIN{c=0} /^---$/{c++; next} c==1{print; next} c==2{exit}' "$file"
}

# Pipe to yq for structured access
parse_frontmatter doc.md | yq '.title'
```
