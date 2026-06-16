# Date & Time

## time package

```go
import "time"

now := time.Now()                                // local
utc := time.Now().UTC()                          // UTC
unix := time.Now().Unix()                        // timestamp
unixNano := time.Now().UnixNano()                // nanosecond
```

### Formatting / Parsing

```go
// Format (use the reference time: Mon Jan 2 15:04:05 MST 2006)
now.Format("2006-01-02 15:04:05")           // "2025-06-15 14:30:00"
now.Format(time.RFC3339)                     // "2025-06-15T14:30:00Z"
now.Format("2006-01-02T15:04:05Z07:00")      // ISO 8601

// Parse
t, _ := time.Parse("2006-01-02", "2025-06-15")
t, _ := time.Parse(time.RFC3339, "2025-06-15T14:30:00Z")
```

### Reference time layout

```
Mon Jan 2 15:04:05 MST 2006
// Components:
2006  → year
01    → month
02    → day
15    → hour (24h)
03    → hour (12h)
04    → minute
05    → second
MST   → timezone
PM    → AM/PM
```

### Constants

```go
time.Second          // 1s
time.Millisecond     // 1ms
time.Microsecond     // 1µs
time.Nanosecond      // 1ns
time.Minute          // 1m
time.Hour            // 1h
```

## Duration

```go
time.Sleep(2 * time.Second)
time.Sleep(500 * time.Millisecond)

// Parse duration strings
d, _ := time.ParseDuration("1h30m")
d, _ := time.ParseDuration("500ms")

// Measure
start := time.Now()
// ... work ...
elapsed := time.Since(start)
fmt.Println(elapsed)           // "1.234s"
fmt.Println(elapsed.Seconds()) // 1.234
```

## Ticker (periodic)

```go
ticker := time.NewTicker(30 * time.Second)
done := make(chan bool)

go func() {
    for {
        select {
        case <-ticker.C:
            healthCheck()
        case <-done:
            ticker.Stop()
            return
        }
    }
}()

// Stop later
close(done)
```

## Timer (one-shot)

```go
timer := time.NewTimer(10 * time.Second)

select {
case <-timer.C:
    fmt.Println("Timer expired")
case <-ctx.Done():
    timer.Stop()
}
```

## Timezone

```go
loc, _ := time.LoadLocation("Europe/Belgrade")
now := time.Now().In(loc)
fmt.Println(now)

// Convert
utc := time.Now().UTC()
local := utc.In(time.Local)
```

## robfig/cron (scheduling)

```bash
go get github.com/robfig/cron/v3
```

```go
import "github.com/robfig/cron/v3"

c := cron.New()

c.AddFunc("@every 30s", func() {
    fmt.Println("Every 30 seconds")
})

c.AddFunc("0 * * * *", func() {
    fmt.Println("Every hour")
})

c.AddFunc("0 3 * * *", func() {
    fmt.Println("Daily at 3am")
})

c.AddFunc("@daily", func() {
    fmt.Println("Daily")
})

c.Start()
defer c.Stop()
select {} // block
```

## Useful patterns

```go
// Retry with backoff
func retry(attempts int, sleep time.Duration, fn func() error) error {
    var err error
    for i := 0; i < attempts; i++ {
        if err = fn(); err == nil {
            return nil
        }
        time.Sleep(sleep)
        sleep *= 2
    }
    return fmt.Errorf("after %d attempts: %w", attempts, err)
}

// Until next occurrence
func nextMidnight() time.Duration {
    now := time.Now()
    next := now.Add(24 * time.Hour)
    next = time.Date(next.Year(), next.Month(), next.Day(), 0, 0, 0, 0, next.Location())
    return next.Sub(now)
}

// Rate limit
func rateLimit(calls int, per time.Duration) func() {
    interval := per / time.Duration(calls)
    ticker := time.NewTicker(interval)
    return func() {
        <-ticker.C
    }
}
```
