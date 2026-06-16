# Working with APIs

## requests (most common HTTP client)

```python
import requests

# GET
resp = requests.get(
    "https://api.github.com/repos/psf/requests",
    headers={"Accept": "application/vnd.github.v3+json"},
    timeout=10,
)
resp.raise_for_status()
data = resp.json()

# POST
resp = requests.post(
    "https://api.example.com/deploy",
    json={"env": "production", "version": "v2.1.0"},
    headers={"Authorization": f"Bearer {API_TOKEN}"},
    timeout=30,
)

# Query params
resp = requests.get(
    "https://api.example.com/search",
    params={"q": "python", "page": 1, "per_page": 50},
)
```

## Session (connection reuse)

```python
session = requests.Session()
session.headers.update({"Authorization": f"Bearer {API_TOKEN}"})
session.timeout = 15

for page in range(1, 6):
    resp = session.get(f"https://api.example.com/items?page={page}")
    resp.raise_for_status()
    process(resp.json())
```

## httpx (modern async-capable alternative)

```python
import httpx

# Sync
with httpx.Client() as client:
    resp = client.get("https://api.example.com/health", timeout=10)
    print(resp.json())

# Async
import asyncio

async def fetch():
    async with httpx.AsyncClient() as client:
        resp = await client.get("https://api.example.com/health", timeout=10)
        return resp.json()

result = asyncio.run(fetch())
```

## Error handling

```python
import requests
from requests.exceptions import (
    RequestException,
    ConnectionError,
    Timeout,
    HTTPError,
)

def call_api(url: str, **kwargs) -> dict | None:
    try:
        resp = requests.get(url, timeout=10, **kwargs)
        resp.raise_for_status()
        return resp.json()
    except ConnectionError:
        log.error("Connection failed: %s", url)
    except Timeout:
        log.error("Request timed out: %s", url)
    except HTTPError as e:
        log.error("HTTP %s: %s", e.response.status_code, e.response.text)
    except RequestException as e:
        log.error("Request failed: %s", e)
    return None
```

## Rate limiting

```python
import time
from functools import wraps

def rate_limit(calls: int, period: float = 1.0):
    def decorator(func):
        last_reset = time.monotonic()
        counter = 0

        @wraps(func)
        def wrapper(*args, **kwargs):
            nonlocal last_reset, counter
            now = time.monotonic()
            if now - last_reset >= period:
                counter = 0
                last_reset = now
            if counter >= calls:
                sleep_time = period - (now - last_reset)
                if sleep_time > 0:
                    time.sleep(sleep_time)
                counter = 0
                last_reset = time.monotonic()
            counter += 1
            return func(*args, **kwargs)
        return wrapper
    return decorator

@rate_limit(calls=10, period=1.0)
def call_api(url: str) -> dict:
    ...
```

## Retry with exponential backoff

```python
import time
from functools import wraps

def retry(max_retries: int = 3, base_delay: float = 1.0, backoff: float = 2.0):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            last_exc = None
            for attempt in range(max_retries):
                try:
                    return func(*args, **kwargs)
                except (ConnectionError, Timeout, HTTPError) as e:
                    last_exc = e
                    delay = base_delay * (backoff ** attempt)
                    log.warning("Attempt %d failed, retrying in %.1fs: %s",
                                attempt + 1, delay, e)
                    time.sleep(delay)
            raise last_exc  # type: ignore
        return wrapper
    return decorator
```

## Health check endpoint

```python
def check_service_health(url: str) -> bool:
    try:
        resp = requests.get(f"{url}/health", timeout=5)
        return resp.status_code == 200
    except RequestException:
        return False

def wait_for_service(url: str, timeout: float = 60.0) -> bool:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if check_service_health(url):
            return True
        time.sleep(2)
    return False
```
