# Datetime & Scheduling

## datetime module

```python
from datetime import datetime, date, time, timedelta, timezone

# Current time
now = datetime.now()                    # local (naive)
utc_now = datetime.now(timezone.utc)    # timezone-aware

# Construct
dt = datetime(2025, 6, 15, 14, 30, 0)
d = date(2025, 6, 15)
t = time(14, 30, 0)

# Formatting
dt.isoformat()                          # "2025-06-15T14:30:00"
dt.strftime("%Y-%m-%d %H:%M:%S")        # "2025-06-15 14:30:00"
datetime.strptime("2025-06-15", "%Y-%m-%d")  # parse string
```

## Common format codes

| Code | Meaning | Example |
|------|---------|---------|
| `%Y` | Year (4-digit) | 2025 |
| `%m` | Month (01-12) | 06 |
| `%d` | Day (01-31) | 15 |
| `%H` | Hour (00-23) | 14 |
| `%M` | Minute (00-59) | 30 |
| `%S` | Second (00-59) | 00 |
| `%f` | Microsecond | 123456 |
| `%z` | UTC offset | +0000 |
| `%Z` | Timezone name | UTC |

## Timedelta arithmetic

```python
from datetime import datetime, timedelta

now = datetime.now()
yesterday = now - timedelta(days=1)
next_week = now + timedelta(weeks=1)
two_hours_ago = now - timedelta(hours=2)

# Difference
delta = next_week - now
delta.days        # 7
delta.total_seconds()  # 604800.0
```

## Timezone handling

```python
from datetime import datetime, timezone, timedelta

utc = datetime.now(timezone.utc)
cet = utc.astimezone(timezone(timedelta(hours=1)))
eastern = utc.astimezone(timezone(timedelta(hours=-5)))

# Using zoneinfo (Python 3.9+)
from zoneinfo import ZoneInfo
tz = ZoneInfo("Europe/Belgrade")
local = datetime.now(tz)

# List all zones
import zoneinfo
print(sorted(zoneinfo.available_timezones())[:10])
```

## Timestamps

```python
from datetime import datetime
import time

# Unix timestamp
ts = datetime.now().timestamp()           # 1747234567.123
dt = datetime.fromtimestamp(ts)           # back to datetime
utc = datetime.fromtimestamp(ts, tz=timezone.utc)

# High-resolution
time.monotonic()     # monotonic clock (for measuring intervals)
time.perf_counter()  # highest resolution (includes sleep)
```

## Scheduling patterns

### Simple sleep loop

```python
import time

def periodic(interval: float):
    while True:
        try:
            task()
        except Exception as e:
            log.error("Task failed: %s", e)
        time.sleep(interval)
```

### Cron-like scheduling (schedule library)

```python
# pip install schedule
import schedule

def backup():
    log.info("Running backup...")

def health_check():
    log.info("Health check...")

schedule.every(10).minutes.do(health_check)
schedule.every().hour.do(job)
schedule.every().day.at("03:00").do(backup)
schedule.every().monday.at("09:00").do(job)

while True:
    schedule.run_pending()
    time.sleep(1)
```

### APScheduler (advanced)

```python
# pip install apscheduler
from apscheduler.schedulers.blocking import BlockingScheduler

scheduler = BlockingScheduler()

@scheduler.scheduled_job("interval", minutes=30)
def health_check():
    ...

@scheduler.scheduled_job("cron", hour=3, minute=0)
def nightly_backup():
    ...

scheduler.start()
```

### Cron expression parser

```python
# pip install croniter
from croniter import croniter
from datetime import datetime

cron = croniter("*/5 * * * *", datetime.now())
next_run = cron.get_next(datetime)
prev_run = cron.get_prev(datetime)
```

## Timeit (measuring execution)

```python
import timeit

# Single expression
elapsed = timeit.timeit("sum(range(100))", number=10000)

# Function
def do_work():
    ...

elapsed = timeit.timeit(do_work, number=100)

# Context manager
from contextlib import contextmanager

@contextmanager
def timer(name: str = ""):
    start = time.perf_counter()
    yield
    elapsed = time.perf_counter() - start
    log.info("%s took %.3fs", name, elapsed)

with timer("deploy"):
    deploy()
```

## Best practices

- Always use timezone-aware datetime in production
- Store timestamps as UTC in databases/logs
- Convert to local time only for display
- Use `time.monotonic()` for measuring durations (not affected by system clock changes)
- Use `croniter` or `schedule` libraries instead of raw `time.sleep()` for serious scheduling
- Prefer ISO 8601 format for logs and data exchange
