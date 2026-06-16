# Deployment & Rollback

## Simple Rsync Deploy

```bash
#!/bin/bash
set -euo pipefail

DEPLOY_DIR="/opt/myapp"
BUILD_DIR="./build"
BACKUP_DIR="/opt/backups/deploy-$(date +%Y%m%d_%H%M%S)"

# 1. Backup current
if [[ -d "$DEPLOY_DIR/current" ]]; then
    cp -a "$DEPLOY_DIR/current" "$BACKUP_DIR"
    echo "Backed up current to $BACKUP_DIR"
fi

# 2. Deploy new version
rsync -a --delete "$BUILD_DIR/" "$DEPLOY_DIR/current/"
echo "Files deployed"

# 3. Health check
sleep 3
if ! curl -sf http://localhost:8080/health > /dev/null; then
    echo "Health check FAILED — rolling back"
    rm -rf "$DEPLOY_DIR/current"
    if [[ -d "$BACKUP_DIR" ]]; then
        cp -a "$BACKUP_DIR" "$DEPLOY_DIR/current"
        echo "Rolled back to $BACKUP_DIR"
    fi
    exit 1
fi

# 4. Cleanup old backups (keep last 5)
ls -t /opt/backups/ | tail -n +6 | xargs -I {} rm -rf "/opt/backups/{}"

echo "Deploy successful"
```

## Blue-Green Deploy

```bash
#!/bin/bash
set -euo pipefail

APP_NAME="myapp"
GREEN_DIR="/opt/${APP_NAME}/green"
BLUE_DIR="/opt/${APP_NAME}/blue"
ACTIVE_LINK="/opt/${APP_NAME}/active"
BUILD_DIR="./build"

# Determine target (deploy to inactive slot)
if [[ "$(readlink $ACTIVE_LINK)" == "$GREEN_DIR" ]]; then
    TARGET="$BLUE_DIR"
    NEW_ACTIVE="green"
else
    TARGET="$GREEN_DIR"
    NEW_ACTIVE="blue"
fi

echo "Deploying to $TARGET..."

# Deploy
rsync -a --delete "$BUILD_DIR/" "$TARGET/"

# Health check on target
# (Assuming running on different port, or just files check)
if ! curl -sf http://localhost:8080/health > /dev/null; then
    echo "Health check failed"
    exit 1
fi

# Switch traffic
ln -snf "$TARGET" "$ACTIVE_LINK"
echo "Switched active to $ACTIVE_LINK -> $TARGET"

# Reload service
systemctl reload "$APP_NAME" || systemctl restart "$APP_NAME"
```

## Database Migration Rollback

```bash
run_migrations() {
    local version="$1"

    echo "Running migrations: v$version"
    # psql -d mydb -f "migrations/v${version}_up.sql"

    # Record version
    echo "$version" > /opt/myapp/DB_VERSION
}

rollback_migrations() {
    local from_version="$1" to_version="$2"

    echo "Rolling back from v$from_version to v$to_version"
    # psql -d mydb -f "migrations/v${from_version}_down.sql"

    echo "$to_version" > /opt/myapp/DB_VERSION
}

# In deploy script
run_migrations "2.1.0" || {
    echo "Migration failed — rolling back"
    rollback_migrations "2.1.0" "$(cat /opt/myapp/DB_VERSION.prev)"
    exit 1
}
```

## Canary Deploy (Percentage-Based)

```bash
# Route a percentage of traffic to new version
# Requires load balancer (nginx/haproxy)

# Nginx example: canary via weight
canary_up() {
    local weight="${1:-5}"  # default 5%
    cat > /etc/nginx/conf.d/canary.conf << EOF
upstream app {
    server 127.0.0.1:8080 weight=$((100 - weight));
    server 127.0.0.1:8081 weight=$weight;
}
EOF
    nginx -s reload
}

canary_down() {
    rm -f /etc/nginx/conf.d/canary.conf
    nginx -s reload
}
```

## Deployment Verification

```bash
verify_deploy() {
    local version="$1" url="${2:-http://localhost:8080}"

    # Check version endpoint
    if curl -sf "$url/version" | grep -q "$version"; then
        echo "Version $version confirmed"
    else
        echo "Version mismatch" >&2
        return 1
    fi

    # Run smoke tests
    curl -sf "$url/health" > /dev/null || { echo "Health check failed"; return 1; }
    curl -sf "$url/api/status" > /dev/null || { echo "API status failed"; return 1; }
    curl -sf -o /dev/null -w "Response: %{http_code}\n" "$url/" || { echo "Homepage failed"; return 1; }

    echo "All checks passed"
}
```
