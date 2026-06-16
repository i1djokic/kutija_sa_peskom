# Logging

## log crate (simple, stdlib-like)

```toml
[dependencies]
log = "0.4"
env_logger = "0.11"
```

```rust
use log::{info, warn, error, debug, trace};

fn main() {
    env_logger::init();

    info!("Starting server on port {}", port);
    warn!("Disk space low: {:.1}%", pct);
    error!("Connection failed: {}", err);
    debug!("Loaded {} config entries", count);
    trace!("Entering function parse_config");
}
```

```bash
# Control log level via RUST_LOG env var
RUST_LOG=info cargo run
RUST_LOG=debug cargo run
RUST_LOG=myapp=debug,warn cargo run
RUST_LOG=error cargo run

# Module-level filtering
RUST_LOG=myapp::config=debug,myapp::network=info

# With timestamps
RUST_LOG=info RUST_LOG_STYLE=always cargo run
```

### Custom logger configuration

```rust
use env_logger::{Builder, Env};

fn main() {
    Builder::from_env(Env::default().default_filter_or("info"))
        .format_timestamp_millis()
        .format_module_path(true)
        .init();
}
```

## tracing (structured, async-aware)

```toml
[dependencies]
tracing = "0.1"
tracing-subscriber = "0.3"
```

```rust
use tracing::{info, warn, error, debug, instrument};
use tracing_subscriber;

fn main() {
    tracing_subscriber::fmt()
        .with_env_filter("info")
        .init();

    let port = 8080;
    info!(port, "server starting");
}

// Structured fields
info!(
    host = "localhost",
    port = 8080,
    env = "production",
    "deploying application"
);

warn!(
    percent_free = 12.5,
    mount = "/data",
    "disk space low"
);

error!(
    error = %err,
    host = %host,
    retry = attempt,
    "connection failed"
);

// Span (for tracing context across functions)
#[instrument]
fn deploy(env: &str) -> Result<()> {
    info!("deploying");  // automatically includes env field
    // ... nested spans inherit context
    Ok(())
}

// Manual span
let span = tracing::span!(tracing::Level::INFO, "request", method = "GET", path = "/health");
let _guard = span.enter();
info!("processing");  // within span context
// _guard dropped = span exited
```

### Log file + console

```rust
use tracing_subscriber::fmt::format::FmtSpan;

let file = std::fs::File::create("app.log")?;

tracing_subscriber::fmt()
    .with_env_filter("info")
    .with_writer(std::sync::Mutex::new(file))
    .with_span_events(FmtSpan::CLOSE)
    .init();
```

## fern (flexible, multi-output)

```toml
[dependencies]
fern = "0.7"
log = "0.4"
```

```rust
use log::LevelFilter;

fern::Dispatch::new()
    .format(|out, message, record| {
        out.finish(format_args!(
            "[{} {} {}] {}",
            chrono::Local::now().format("%Y-%m-%d %H:%M:%S"),
            record.level(),
            record.target(),
            message
        ))
    })
    .level(LevelFilter::Info)
    .level_for("myapp::config", LevelFilter::Debug)
    .chain(std::io::stderr())
    .chain(fern::log_file("app.log")?)
    .apply()?;
```

## Best practices

- Use `RUST_LOG` env var for runtime log level control
- Use structured logging (`tracing`) over format strings for production
- Log to stderr, reserve stdout for program output
- Use `#[instrument]` for tracing function calls with context
- Always log errors with context (`error = %err`, `host = %host`)
- Set default log level to `info` in production
- Use `debug`/`trace` for verbose diagnostics (disabled by default)
- Rotate logs externally (logrotate) or via `rolling-file` crate
