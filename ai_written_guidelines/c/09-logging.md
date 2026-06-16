# Logging

## syslog (POSIX)

```c
#include <syslog.h>

// At startup
openlog("myapp", LOG_PID | LOG_NDELAY, LOG_USER);

// Log messages
syslog(LOG_INFO, "Service started on port %d", port);
syslog(LOG_WARNING, "Disk space low: %.1f%% free", pct);
syslog(LOG_ERR, "Connection failed: %s", strerror(errno));

// Close
closelog();
```

### Priorities

```c
LOG_EMERG    // System is unusable
LOG_ALERT    // Action must be taken immediately
LOG_CRIT     // Critical conditions
LOG_ERR      // Error conditions
LOG_WARNING  // Warning conditions
LOG_NOTICE   // Normal but significant
LOG_INFO     // Informational
LOG_DEBUG    // Debug-level messages
```

## Custom logging (stderr + file)

```c
#include <stdio.h>
#include <time.h>
#include <stdarg.h>

typedef enum {
    LOG_DEBUG,
    LOG_INFO,
    LOG_WARN,
    LOG_ERROR,
} LogLevel;

static const char *level_names[] = {
    "DEBUG", "INFO", "WARN", "ERROR"
};

static LogLevel current_level = LOG_INFO;
static FILE *log_file = NULL;

void log_init(const char *path, LogLevel level) {
    current_level = level;
    if (path) log_file = fopen(path, "a");
}

void log_msg(LogLevel level, const char *fmt, ...) {
    if (level < current_level) return;

    time_t now = time(NULL);
    struct tm *tm = localtime(&now);

    FILE *out = log_file ? log_file : stderr;
    fprintf(out, "%04d-%02d-%02d %02d:%02d:%02d [%s] ",
        tm->tm_year + 1900, tm->tm_mon + 1, tm->tm_mday,
        tm->tm_hour, tm->tm_min, tm->tm_sec,
        level_names[level]);

    va_list args;
    va_start(args, fmt);
    vfprintf(out, fmt, args);
    va_end(args);
    fprintf(out, "\n");
    fflush(out);
}

void log_close(void) {
    if (log_file) fclose(log_file);
}

// Macros for convenience
#define log_debug(fmt, ...) log_msg(LOG_DEBUG, fmt, ##__VA_ARGS__)
#define log_info(fmt, ...)  log_msg(LOG_INFO,  fmt, ##__VA_ARGS__)
#define log_warn(fmt, ...)  log_msg(LOG_WARN,  fmt, ##__VA_ARGS__)
#define log_error(fmt, ...) log_msg(LOG_ERROR, fmt, ##__VA_ARGS__)
```

### Usage

```c
log_init("app.log", LOG_DEBUG);
log_info("Starting server on port %d", port);
log_warn("Memory usage high: %.1f%%", pct);
log_error("Failed to connect: %s", strerror(errno));
log_close();
```

## Log to both file and stderr

```c
void log_init_dual(const char *path, LogLevel level) {
    current_level = level;
    if (path) log_file = fopen(path, "a");
}
// log_msg() above writes to log_file if set, else stderr

// Alternatively, always write to both:
void log_both(LogLevel level, const char *fmt, ...) {
    if (level < current_level) return;
    va_list args1, args2;
    va_start(args1, fmt);
    va_copy(args2, args1);
    vfprintf(stderr, fmt, args1);
    if (log_file) vfprintf(log_file, fmt, args2);
    va_end(args2);
    va_end(args1);
}
```

## Verbosity-controlled logging

```c
static int verbosity = 0;

void set_verbosity(int v) { verbosity = v; }

#define vlog(level, vlevel, fmt, ...) \
    do { \
        if (vlevel <= verbosity) \
            fprintf(stderr, "[%s] " fmt "\n", level, ##__VA_ARGS__); \
    } while (0)

// Usage
vlog("INFO", 0, "Starting...");
vlog("DEBUG", 1, "Loaded config with %d entries", count);
vlog("TRACE", 2, "Parsing field: %s", field);
```
