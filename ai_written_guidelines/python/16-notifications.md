# Notifications & Alerting

## Email (smtplib)

```python
import smtplib
from email.message import EmailMessage

def send_email(
    to: str,
    subject: str,
    body: str,
    smtp_host: str = "localhost",
    smtp_port: int = 25,
    from_addr: str = "automation@example.com",
) -> None:
    msg = EmailMessage()
    msg.set_content(body)
    msg["Subject"] = subject
    msg["From"] = from_addr
    msg["To"] = to

    with smtplib.SMTP(smtp_host, smtp_port) as server:
        server.send_message(msg)
```

### With authentication and TLS

```python
def send_email_smtp(
    to: str,
    subject: str,
    body: str,
    user: str,
    password: str,
    host: str = "smtp.gmail.com",
    port: int = 587,
) -> None:
    msg = EmailMessage()
    msg.set_content(body)
    msg["Subject"] = subject
    msg["From"] = user
    msg["To"] = to

    with smtplib.SMTP(host, port) as server:
        server.starttls()
        server.login(user, password)
        server.send_message(msg)
```

## Slack webhooks

```python
import requests

def slack_alert(webhook_url: str, message: str, level: str = "info") -> bool:
    emoji = {"info": ":information_source:", "warn": ":warning:", "error": ":red_circle:"}
    payload = {
        "text": f"{emoji.get(level, '')} {message}",
        "username": "DeployBot",
    }
    resp = requests.post(webhook_url, json=payload, timeout=10)
    return resp.status_code == 200
```

## Slack via SDK

```python
# pip install slack-sdk
from slack_sdk import WebClient

def slack_message(token: str, channel: str, text: str) -> None:
    client = WebClient(token=token)
    client.chat_postMessage(channel=channel, text=text)
```

## Telegram

```python
def telegram_alert(bot_token: str, chat_id: str, message: str) -> bool:
    url = f"https://api.telegram.org/bot{bot_token}/sendMessage"
    resp = requests.post(url, json={
        "chat_id": chat_id,
        "text": message,
        "parse_mode": "HTML",
    }, timeout=10)
    return resp.status_code == 200
```

## Discord webhooks

```python
def discord_alert(webhook_url: str, message: str) -> bool:
    payload = {
        "content": message,
        "username": "DeployBot",
    }
    resp = requests.post(webhook_url, json=payload, timeout=10)
    return resp.status_code == 204
```

## PagerDuty Events API (v2)

```python
def pagerduty_alert(
    routing_key: str,
    summary: str,
    source: str = "automation",
    severity: str = "critical",
) -> bool:
    payload = {
        "routing_key": routing_key,
        "event_action": "trigger",
        "payload": {
            "summary": summary,
            "source": source,
            "severity": severity,
        },
    }
    resp = requests.post(
        "https://events.pagerduty.com/v2/enqueue",
        json=payload,
        timeout=10,
    )
    return resp.status_code == 202
```

## Notification router

```python
import enum
from dataclasses import dataclass, field

class NotifyLevel(enum.Enum):
    INFO = "info"
    WARN = "warn"
    ERROR = "error"

@dataclass
class Notifier:
    slack_webhook: str | None = None
    email_config: dict | None = None
    telegram_config: dict | None = None

    def send(self, message: str, level: NotifyLevel = NotifyLevel.INFO) -> None:
        failures = []

        if self.slack_webhook:
            if not slack_alert(self.slack_webhook, message, level.value):
                failures.append("slack")

        if self.email_config:
            try:
                send_email(**self.email_config, body=message)
            except Exception:
                failures.append("email")

        if self.telegram_config:
            try:
                telegram_alert(**self.telegram_config, message=message)
            except Exception:
                failures.append("telegram")

        if failures:
            log.error("Failed to send via: %s", ", ".join(failures))

    def info(self, message: str) -> None:
        self.send(message, NotifyLevel.INFO)

    def warn(self, message: str) -> None:
        self.send(message, NotifyLevel.WARN)

    def error(self, message: str) -> None:
        self.send(message, NotifyLevel.ERROR)
```

## Alert on failure pattern

```python
def notify_on_failure(notifier: Notifier):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            try:
                return func(*args, **kwargs)
            except Exception as e:
                notifier.error(f"`{func.__name__}` failed: {e}")
                raise
        return wrapper
    return decorator

@notify_on_failure(notifier)
def deploy(env: str) -> None:
    ...
```
