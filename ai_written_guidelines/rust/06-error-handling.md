# Error Handling

## Option

```rust
fn find_user(id: u32) -> Option<String> {
    if id == 1 {
        Some("Alice".into())
    } else {
        None
    }
}

// Unwrap (panics if None)
let name = find_user(1).unwrap();
let name = find_user(1).expect("user should exist");

// Combinators
let name = find_user(1).unwrap_or("default".into());
let name = find_user(1).unwrap_or_else(|| fallback());

// Map / and_then
let upper = find_user(1).map(|s| s.to_uppercase());
let name = find_user(1).and_then(|s| s.split(' ').next().map(String::from));
```

## Result

```rust
fn read_config(path: &str) -> Result<String, std::io::Error> {
    std::fs::read_to_string(path)
}

// Unwrap (panics on error)
let content = read_config("config.yaml").unwrap();
let content = read_config("config.yaml").expect("config file");

// Propagation with ?
fn load_config() -> Result<Config, Box<dyn std::error::Error>> {
    let content = std::fs::read_to_string("config.yaml")?;
    let cfg: Config = serde_yaml::from_str(&content)?;
    Ok(cfg)
}
```

## Custom errors

### thiserror (derive macro)

```toml
[dependencies]
thiserror = "1"
```

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum AutomationError {
    #[error("config error: {0}")]
    Config(String),

    #[error("io error: {0}")]
    Io(#[from] std::io::Error),

    #[error("network error: {0}")]
    Network(String),

    #[error("command '{cmd}' failed with code {code}")]
    Command {
        cmd: String,
        code: i32,
    },
}

// Usage
fn deploy(env: &str) -> Result<(), AutomationError> {
    if env.is_empty() {
        return Err(AutomationError::Config("env required".into()));
    }
    let config = std::fs::read_to_string("config.yaml")?;  // auto-converted via #[from]
    Ok(())
}
```

### anyhow (for applications)

```toml
[dependencies]
anyhow = "1"
```

```rust
use anyhow::{Result, Context, anyhow, bail};

fn main() -> Result<()> {
    let config = std::fs::read_to_string("config.yaml")
        .context("failed to read config file")?;

    let port: u16 = config.parse()
        .map_err(|_| anyhow!("invalid port in config"))?;

    if port == 0 {
        bail!("port must be non-zero");
    }

    Ok(())
}
```

## Error handling patterns

```rust
// Mapping errors
fn parse_port(s: &str) -> Result<u16, String> {
    s.parse::<u16>().map_err(|e| format!("invalid port: {}", e))
}

// Fallback
let port = parse_port("8080").unwrap_or(8080);

// Log and continue
if let Err(e) = backup() {
    log::warn!("Backup failed: {}", e);
}

// Ignore (you usually shouldn't)
let _ = do_something();  // intentionally ignored
```

## Best practices

- Use `Result` for fallible operations, never panic in libraries
- Use `thiserror` for library crates (defined error types)
- Use `anyhow` for applications and CLI tools
- Prefer `?` operator over manual `match`
- Use `.context()` from `anyhow` to add context to errors
- Only `.unwrap()` / `.expect()` when you're certain it won't fail
- Document error conditions in doc comments
