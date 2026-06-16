# Date & Time

## time.h basics

```c
#include <time.h>
#include <stdio.h>

time_t now = time(NULL);            // current Unix timestamp
struct tm *tm = localtime(&now);    // broken-down local time

char buf[64];
strftime(buf, sizeof(buf), "%Y-%m-%d %H:%M:%S", tm);
printf("%s\n", buf);               // "2025-06-15 14:30:00"
```

## strftime format codes

| Code | Meaning | Example |
|------|---------|---------|
| `%Y` | Year (4-digit) | 2025 |
| `%m` | Month (01-12) | 06 |
| `%d` | Day (01-31) | 15 |
| `%H` | Hour (00-23) | 14 |
| `%M` | Minute (00-59) | 30 |
| `%S` | Second (00-59) | 00 |
| `%a` | Abbreviated weekday | Mon |
| `%b` | Abbreviated month | Jun |
| `%Z` | Timezone name | UTC |

## Parsing strings

```c
struct tm tm = {0};
strptime("2025-06-15 14:30:00", "%Y-%m-%d %H:%M:%S", &tm);
time_t t = mktime(&tm);  // convert to timestamp
```

## Timestamps

```c
time_t now = time(NULL);
printf("Unix timestamp: %ld\n", now);

// High-resolution (POSIX)
struct timespec ts;
clock_gettime(CLOCK_MONOTONIC, &ts);
printf("Monotonic: %ld.%09ld\n", ts.tv_sec, ts.tv_nsec);

clock_gettime(CLOCK_REALTIME, &ts);
printf("Realtime: %ld.%09ld\n", ts.tv_sec, ts.tv_nsec);
```

## Timing / measuring duration

```c
#include <time.h>

struct timespec start, end;
clock_gettime(CLOCK_MONOTONIC, &start);

// ... do work ...

clock_gettime(CLOCK_MONOTONIC, &end);
double elapsed = (end.tv_sec - start.tv_sec)
    + (end.tv_nsec - start.tv_nsec) / 1e9;
printf("Elapsed: %.3f seconds\n", elapsed);
```

## UTC vs local

```c
time_t now = time(NULL);

struct tm *local = localtime(&now);   // local time
struct tm *utc   = gmtime(&now);      // UTC

char buf[64];
strftime(buf, sizeof(buf), "%Y-%m-%dT%H:%M:%SZ", utc);
printf("ISO 8601 UTC: %s\n", buf);   // "2025-06-15T12:30:00Z"
```

## Sleep / delay

```c
#include <unistd.h>

sleep(1);              // seconds
usleep(1000000);       // microseconds
nanosleep(&ts, NULL);  // nanoseconds
```

## Timer (interval)

```c
#include <signal.h>
#include <sys/time.h>
#include <stdio.h>

volatile sig_atomic_t tick = 0;

void timer_handler(int sig) {
    tick++;
}

int main(void) {
    struct sigaction sa = {0};
    sa.sa_handler = timer_handler;
    sigaction(SIGALRM, &sa, NULL);

    struct itimerval timer = {
        .it_interval = {1, 0},   // 1 second interval
        .it_value = {1, 0},      // first fire in 1s
    };
    setitimer(ITIMER_REAL, &timer, NULL);

    while (1) {
        if (tick) { tick = 0; printf("tick\n"); }
    }
}
```

## Cron-like scheduling pattern

```c
#include <time.h>
#include <unistd.h>

void every_n_seconds(int interval, void (*task)(void)) {
    time_t last = time(NULL);
    while (1) {
        time_t now = time(NULL);
        if (now - last >= interval) {
            task();
            last = now;
        }
        sleep(1);
    }
}
```
