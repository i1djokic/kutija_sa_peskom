# Subprocess & System Automation

## std::process::Command

```rust
use std::process::Command;

// Simple output
let output = Command::new("ls")
    .args(["-la", "/tmp"])
    .output()?;

println!("stdout: {}", String::from_utf8_lossy(&output.stdout));
println!("stderr: {}", String::from_utf8_lossy(&output.stderr));
println!("exit code: {}", output.status.code().unwrap_or(-1));
```

### Run and check

```rust
Command::new("systemctl")
    .args(["restart", "nginx"])
    .status()
    .context("failed to execute systemctl")?
    .success()
    .then_some(())
    .ok_or_else(|| anyhow!("systemctl failed"))?;
```

### Capture output

```rust
let output = Command::new("deploy.sh")
    .arg("--env")
    .arg("production")
    .output()?;

if output.status.success() {
    let stdout = String::from_utf8_lossy(&output.stdout);
    println!("{}", stdout);
} else {
    let stderr = String::from_utf8_lossy(&output.stderr);
    eprintln!("Failed: {}", stderr);
}
```

### With environment and working directory

```rust
let output = Command::new("backup.sh")
    .current_dir("/opt/myapp")
    .env("MYAPP_ENV", "production")
    .env_remove("SENSITIVE_VAR")
    .output()?;
```

### Stdin pipe

```rust
use std::process::{Command, Stdio};

let mut child = Command::new("sort")
    .stdin(Stdio::piped())
    .stdout(Stdio::piped())
    .spawn()?;

// Write to stdin
child.stdin.take().unwrap().write_all(b"3\n1\n2\n")?;

// Read stdout
let output = child.wait_with_output()?;
println!("{}", String::from_utf8_lossy(&output.stdout));
// Output: "1\n2\n3\n"
```

### Pipe commands together

```rust
let grep = Command::new("grep")
    .arg("error")
    .stdout(Stdio::piped())
    .spawn()?;

let wc = Command::new("wc")
    .arg("-l")
    .stdin(grep.stdout.unwrap())
    .output()?;

println!("{}", String::from_utf8_lossy(&wc.stdout));
```

## tokio::process (async)

```toml
[dependencies]
tokio = { version = "1", features = ["process"] }
```

```rust
use tokio::process::Command;

#[tokio::main]
async fn main() -> Result<()> {
    let output = Command::new("ping")
        .args(["-c", "3", "example.com"])
        .output()
        .await?;

    println!("{}", String::from_utf8_lossy(&output.stdout));
    Ok(())
}
```

## Signal handling

```rust
use tokio::signal;

#[tokio::main]
async fn main() -> Result<()> {
    signal::ctrl_c().await?;
    println!("Shutting down...");
    Ok(())
}
```

### With Unix signals

```rust
#[cfg(unix)]
use tokio::signal::unix::{signal, SignalKind};

#[tokio::main]
async fn main() -> Result<()> {
    let mut term = signal(SignalKind::terminate())?;
    let mut int = signal(SignalKind::interrupt())?;

    tokio::select! {
        _ = term.recv() => println!("SIGTERM received"),
        _ = int.recv() => println!("SIGINT received"),
    }

    Ok(())
}
```

## Environment variables

```rust
use std::env;

let host = env::var("HOST").unwrap_or_else(|_| "localhost".into());
let port: u16 = env::var("PORT")
    .ok()
    .and_then(|p| p.parse().ok())
    .unwrap_or(8080);

// Check if set
if let Ok(val) = env::var("API_KEY") {
    println!("API_KEY is set");
}

// Set
env::set_var("MYAPP_ENV", "production");

// Remove
env::remove_var("TEMP_VAR");
```

## Process info

```rust
use std::process;

let pid = process::id();    // current PID
```
