# Logging

## log (stdlib)

```go
import "log"

// Basic
log.Println("Starting server on port", port)
log.Printf("Loaded %d config entries", count)

// Fatal (calls os.Exit(1))
log.Fatal("Failed to connect: ", err)

// Panic (calls panic())
log.Panic("unexpected state")

// Custom prefix and flags
logger := log.New(os.Stderr, "myapp: ", log.Ldate|log.Ltime|log.Lshortfile)
logger.Println("custom logger")
```

### Flags

```go
log.Ldate         // 2025-06-15
log.Ltime         // 14:30:00
log.Lmicroseconds // 14:30:00.123456
log.Lshortfile    // main.go:42
log.Llongfile     // /path/to/main.go:42
log.LUTC          // UTC instead of local
log.Lmsgprefix    // prefix before message
```

## log/slog (structured, Go 1.21+)

```go
import "log/slog"

// JSON format
slog.SetDefault(slog.New(slog.NewJSONHandler(os.Stderr, &slog.HandlerOptions{
    Level: slog.LevelInfo,
})))

// Text format
slog.SetDefault(slog.New(slog.NewTextHandler(os.Stderr, nil)))

// Structured logging
slog.Info("server starting",
    "port", port,
    "host", host,
    "env", env,
)

slog.Warn("disk space low",
    "percent_free", pct,
    "mount", "/data",
)

slog.Error("connection failed",
    "error", err,
    "retry", attempt,
)

// With context
logger := slog.With("service", "web", "version", "2.1.0")
logger.Info("health check passed", "status", 200)

// Custom level
const LevelTrace = slog.Level(-8)
slog.Log(nil, LevelTrace, "trace message", "detail", value)

// Groups
slog.Info("request",
    "method", "GET",
    slog.Group("response",
        "status", 200,
        "size", 1024,
    ),
)
```

## zerolog (structured, zero alloc)

```bash
go get github.com/rs/zerolog/log
```

```go
import "github.com/rs/zerolog/log"

// Global logger
log.Info().Int("port", 8080).Msg("server starting")
log.Warn().Float64("pct", 12.5).Msg("disk space low")
log.Error().Err(err).Str("host", host).Msg("connection failed")

// Debug level (disabled by default)
log.Debug().Int("count", len(items)).Msg("processing")

// Pretty print (development)
log.Logger = log.Output(zerolog.ConsoleWriter{Out: os.Stderr})

// Sub-logger
logger := log.With().Str("service", "web").Logger()
logger.Info().Msg("health check passed")
```

## zap (high performance)

```bash
go get go.uber.org/zap
```

```go
import "go.uber.org/zap"

// Production (JSON, no caller by default)
logger, _ := zap.NewProduction()
defer logger.Sync()

// Development (pretty, debug, caller)
logger, _ := zap.NewDevelopment()

// Structured logging
logger.Info("server starting",
    zap.String("host", host),
    zap.Int("port", port),
    zap.String("env", env),
)

logger.Warn("disk low",
    zap.Float64("percent_free", pct),
)

logger.Error("request failed",
    zap.Error(err),
    zap.Int("status", resp.StatusCode),
)

// Sugar (for printf-style)
sugar := logger.Sugar()
sugar.Infof("Server on %s:%d", host, port)
sugar.Errorf("Failed: %v", err)

// Fields
logger = logger.With(zap.String("service", "web"))
logger.Info("started")
```

## Best practices

- Use structured logging (`slog`, `zerolog`, `zap`) over `log` for production
- Set log level from env var (`LOG_LEVEL=debug`)
- Log to stderr, not stdout (reserve stdout for program output)
- Include request IDs / correlation IDs in structured logs
- Always log errors with context, never `log.Printf("error: %v", err)`
- Use `log.Fatal` only in main, not in libraries
- Rotate logs externally (logrotate) or use `lumberjack`
