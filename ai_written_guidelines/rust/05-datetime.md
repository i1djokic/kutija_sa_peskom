# Date & Time

## chrono crate

```toml
[dependencies]
chrono = "0.4"
```

```rust
use chrono::{Local, Utc, NaiveDateTime, DateTime, Duration, Timelike};
use chrono::format::strftime;

// Current time
let now = Utc::now();                  // UTC
let local = Local::now();              // local time
let ts = Utc::now().timestamp();       // Unix timestamp
```

### Formatting / Parsing

```rust
use chrono::{Utc, NaiveDateTime};

let now = Utc::now();
now.format("%Y-%m-%d %H:%M:%S").to_string();  // "2025-06-15 14:30:00"
now.format("%Y-%m-%dT%H:%M:%SZ").to_string(); // ISO 8601
now.format("%a %b %e %T %Y").to_string();     // "Sun Jun 15 14:30:00 2025"

// Parse
let dt = NaiveDateTime::parse_from_str(
    "2025-06-15 14:30:00",
    "%Y-%m-%d %H:%M:%S"
)?;

let dt = DateTime::parse_from_rfc3339("2025-06-15T14:30:00Z")?;
```

### Format specifiers

| Spec | Meaning | Example |
|------|---------|---------|
| `%Y` | Year (4-digit) | 2025 |
| `%m` | Month (01-12) | 06 |
| `%d` | Day (01-31) | 15 |
| `%H` | Hour (00-23) | 14 |
| `%M` | Minute (00-59) | 30 |
| `%S` | Second (00-59) | 00 |
| `%f` | Microsecond | 123456 |
| `%Z` | Timezone name | UTC |
| `%z` | UTC offset | +0000 |

## Duration

```rust
use chrono::Duration;

let later = Utc::now() + Duration::minutes(30);
let earlier = Utc::now() - Duration::hours(2);
let diff = later - earlier;

diff.num_seconds();     // total seconds
diff.num_minutes();     // total minutes
diff.num_hours();       // total hours
diff.num_days();        // total days
```

## Timing

```rust
use std::time::Instant;

let start = Instant::now();
// ... work ...
let elapsed = start.elapsed();

println!("{:.3}s", elapsed.as_secs_f64());
println!("{}ms", elapsed.as_millis());
```

## Sleep

```rust
use std::time::Duration;
use tokio::time;

// Sync
std::thread::sleep(Duration::from_secs(1));
std::thread::sleep(Duration::from_millis(500));

// Async
time::sleep(Duration::from_secs(1)).await;
```

## Ticker (async periodic)

```rust
use tokio::time::{self, Duration};

#[tokio::main]
async fn main() {
    let mut interval = time::interval(Duration::from_secs(30));

    loop {
        interval.tick().await;
        health_check().await;
    }
}
```

## Timezone handling

```rust
use chrono::{Utc, Local, TimeZone, FixedOffset};

// UTC
let utc = Utc::now();

// Local
let local = Local::now();

// Fixed offset
let est = FixedOffset::east_opt(-5 * 3600).unwrap();
let now_est = Utc::now().with_timezone(&est);

// Parse timezone-aware
let dt = DateTime::parse_from_str(
    "2025-06-15 14:30:00 +0200",
    "%Y-%m-%d %H:%M:%S %z"
)?;
```

## Scheduling with tokio

```rust
use tokio::time::{self, Duration, MissedTickBehavior};

#[tokio::main]
async fn main() {
    let mut interval = time::interval(Duration::from_secs(60));
    interval.set_missed_tick_behavior(MissedTickBehavior::Skip);

    loop {
        interval.tick().await;
        run_backup().await;
    }
}
```

## Useful patterns

```rust
// Retry with backoff
async fn retry<T>(
    f: impl Fn() -> Result<T>,
    max_retries: u32,
    base_delay: Duration,
) -> Result<T> {
    let mut delay = base_delay;
    for attempt in 0..max_retries {
        match f() {
            Ok(val) => return Ok(val),
            Err(e) if attempt < max_retries - 1 => {
                tokio::time::sleep(delay).await;
                delay *= 2;
            }
            Err(e) => return Err(e),
        }
    }
    unreachable!()
}

// Until next occurrence
fn duration_until_next(daily_hour: u32, daily_min: u32) -> Duration {
    let now = Utc::now();
    let next = now.date()
        .and_hms_opt(daily_hour, daily_min, 0)
        .unwrap();
    let next = if next > now { next } else { next + Duration::days(1) };
    (next - now).to_std().unwrap()
}
```
