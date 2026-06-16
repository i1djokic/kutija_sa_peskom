# Working with APIs

## curl — Every Sysadmin's HTTP Client

```bash
# Basic GET
curl https://api.example.com/health

# Get with headers
curl -H "Authorization: Bearer $TOKEN" https://api.example.com/users

# POST JSON
curl -X POST https://api.example.com/deploy \
    -H "Content-Type: application/json" \
    -d '{"service":"nginx","version":"1.25"}'

# POST from file
curl -X POST https://api.example.com/config \
    -d @/etc/myapp/config.json

# Follow redirects (-L)
curl -L https://bit.ly/some-link

# Silent (for scripting)
curl -sf https://api.example.com/health
# -s : silent (no progress)
# -f : fail on HTTP error (non-2xx)
# -S : show errors (even with -s)

# Output to file
curl -o response.json https://api.example.com/data
curl -O https://example.com/file.zip    # preserve filename

# Extract response headers
curl -sI https://example.com            # headers only (HEAD request)
curl -s -D - https://example.com        # include headers in output (-D - = stdout)
```

## curl Error Handling

```bash
# Check HTTP status code
http_code=$(curl -s -o /dev/null -w "%{http_code}" https://api.example.com/health)

if [[ "$http_code" -ne 200 ]]; then
    echo "Health check failed: HTTP $http_code"
    exit 1
fi

# Check curl exit code
if ! curl -sf https://api.example.com/health > /dev/null; then
    echo "API unreachable"
fi
```

## HTTPie — Human-Friendly Alternative

```bash
# httpie is often nicer for interactive use
http https://api.example.com/health
http POST https://api.example.com/deploy service=nginx version=1.25
http -b https://api.example.com/users   # body only (no headers)
http -h https://api.example.com/users   # headers only
```

## Common API Patterns

```bash
# Health check
health_check() {
    local url="${1:-http://localhost:8080/health}"
    local retries="${2:-3}"

    for i in $(seq 1 "$retries"); do
        if curl -sf "$url" > /dev/null; then
            echo "Healthy"
            return 0
        fi
        sleep 2
    done
    echo "Unhealthy after $retries retries" >&2
    return 1
}

# POST with JSON body from variables
post_event() {
    local event="$1" severity="$2"
    curl -sf -X POST "https://hooks.example.com/events" \
        -H "Content-Type: application/json" \
        -d "$(cat <<JSON
{
    "event": "$event",
    "severity": "$severity",
    "host": "$HOSTNAME",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
JSON
        )"
}

# Rate limiting (simple)
for id in "${users[@]}"; do
    curl -sf "https://api.example.com/users/$id" > "user_${id}.json"
    sleep 0.5  # max 2 requests/second
done
```

## Webhook Notification

```bash
notify_slack() {
    local webhook="$1" message="$2"
    curl -sf -X POST "$webhook" \
        -H "Content-Type: application/json" \
        -d "{\"text\": \"$message\"}" > /dev/null
}

# Usage
notify_slack "$SLACK_WEBHOOK" "Deploy of v1.2.3 completed on $HOSTNAME"
```
