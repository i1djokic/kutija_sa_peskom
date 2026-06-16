# Notifications & Alerting

## Slack Webhook

```bash
notify_slack() {
    local webhook="$1" message="$2"
    curl -sf -X POST "$webhook" \
        -H "Content-Type: application/json" \
        -d "{\"text\": \"$message\"}" > /dev/null
}

# Usage
notify_slack "$SLACK_WEBHOOK" "Deploy v1.2.3 completed on $HOSTNAME"

# Rich message with fields
notify_slack_rich() {
    local webhook="$1" title="$2" message="$3" color="${4:-good}"
    curl -sf -X POST "$webhook" \
        -H "Content-Type: application/json" \
        -d "$(cat <<JSON
{
    "attachments": [{
        "color": "$color",
        "title": "$title",
        "text": "$message",
        "fields": [
            {"title": "Host", "value": "$HOSTNAME", "short": true},
            {"title": "Time", "value": "$(date -u +%Y-%m-%dT%H:%M:%SZ)", "short": true}
        ]
    }]
}
JSON
        )" > /dev/null
}
```

## Email Alerts

```bash
# Simple (using mail command — install mailutils/postfix)
send_email() {
    local to="$1" subject="$2" body="$3"
    echo "$body" | mail -s "$subject" "$to"
}

# With attachments
echo "See attached" | mail -s "Daily report" -a /tmp/report.csv ops@example.com

# Using sendmail directly (no local MTA needed)
send_email_smtp() {
    local to="$1" subject="$2" body="$3"
    {
        echo "Subject: $subject"
        echo "To: $to"
        echo ""
        echo "$body"
    } | sendmail -f "noreply@$HOSTNAME" "$to"
}
```

## Telegram Bot

```bash
notify_telegram() {
    local bot_token="$1" chat_id="$2" message="$3"
    curl -sf -X POST "https://api.telegram.org/bot${bot_token}/sendMessage" \
        -d "chat_id=${chat_id}&text=${message}&parse_mode=Markdown" > /dev/null
}

# Usage
notify_telegram "$TG_BOT_TOKEN" "$TG_CHAT_ID" "*Alert:* Disk usage over 90% on $HOSTNAME"
```

## Discord Webhook

```bash
notify_discord() {
    local webhook="$1" message="$2"
    curl -sf -X POST "$webhook" \
        -H "Content-Type: application/json" \
        -d "{\"content\": \"$message\"}" > /dev/null
}

# With embed
notify_discord_embed() {
    local webhook="$1" title="$2" description="$3" color="${4:-65280}"
    curl -sf -X POST "$webhook" \
        -H "Content-Type: application/json" \
        -d "$(cat <<JSON
{
    "embeds": [{
        "title": "$title",
        "description": "$description",
        "color": $color,
        "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    }]
}
JSON
        )" > /dev/null
}
```

## PagerDuty / Incident Triggers

```bash
trigger_pagerduty() {
    local routing_key="$1" summary="$2" severity="${3:-critical}"
    curl -sf -X POST "https://events.pagerduty.com/v2/enqueue" \
        -H "Content-Type: application/json" \
        -d "$(cat <<JSON
{
    "routing_key": "$routing_key",
    "event_action": "trigger",
    "payload": {
        "summary": "$summary",
        "source": "$HOSTNAME",
        "severity": "$severity"
    }
}
JSON
        )"
}
```

## Aggregated Health Report

```bash
send_daily_report() {
    local webhook="$1"

    report=$(cat <<REPORT
*Daily Health Report — $HOSTNAME*
• Uptime: $(uptime -p)
• Memory: $(free -h | awk '/^Mem:/ {print $3"/"$2}')
• Disk: $(df -h / | awk 'NR==2 {print $3"/"$2}') ($(df / | awk 'NR==2 {gsub(/%/,""); print $5}')%)
• Load: $(uptime | awk -F'load average:' '{print $2}')
• Services: $(systemctl --failed | wc -l) failed
REPORT
)

    notify_slack "$webhook" "$report"
}
```
