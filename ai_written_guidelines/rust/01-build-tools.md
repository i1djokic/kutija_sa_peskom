# Build Tools & Cargo

## Cargo basics

```bash
cargo new myapp                 # new binary project
cargo new --lib mylib           # new library project
cargo build                     # debug build
cargo build --release           # release build
cargo run                       # build + run
cargo check                     # check without compiling (fast)
cargo test                      # run tests
cargo doc --open                # build and open documentation
```

## Cargo.toml

```toml
[package]
name = "myapp"
version = "0.1.0"
edition = "2021"
description = "Automation tool"
authors = ["Your Name <you@example.com>"]
license = "MIT"
repository = "https://github.com/user/myapp"

[dependencies]
clap = { version = "4", features = ["derive"] }
serde = { version = "1", features = ["derive"] }
serde_yaml = "0.9"
tokio = { version = "1", features = ["full"] }
reqwest = { version = "0.12", features = ["json"] }
anyhow = "1"
thiserror = "1"

[dev-dependencies]
assert_cmd = "2"
tempfile = "3"

[profile.release]
opt-level = 3
lto = true
codegen-units = 1
strip = true
```

## Features (conditional compilation)

```toml
[features]
default = ["json"]
json = ["serde_json"]
yaml = ["serde_yaml"]
full = ["json", "yaml"]
```

```rust
#[cfg(feature = "json")]
fn parse_json(data: &str) -> Result<Config> { }

#[cfg(not(feature = "json"))]
fn parse_json(data: &str) -> Result<Config> {
    Err(anyhow!("json feature not enabled"))
}
```

## Workspaces

```toml
# Cargo.toml (root)
[workspace]
members = [
    "crates/cli",
    "crates/core",
    "crates/config",
]

resolver = "2"
```

```
myapp/
  Cargo.toml      # workspace root
  crates/
    cli/
      Cargo.toml
      src/
    core/
      Cargo.toml
      src/
    config/
      Cargo.toml
      src/
```

## Build profiles

```toml
[profile.dev]
opt-level = 0
debug = true

[profile.release]
opt-level = 3
debug = false
lto = true
codegen-units = 1
strip = "symbols"    # or "debuginfo"
panic = "abort"

[profile.bench]
inherits = "release"
```

## Cross-compilation

```bash
# Install target
rustup target add aarch64-unknown-linux-gnu
rustup target add x86_64-pc-windows-gnu

# Build
cargo build --release --target aarch64-unknown-linux-gnu
cargo build --release --target x86_64-pc-windows-gnu
```

## Common commands

| Command | Purpose |
|---------|---------|
| `cargo build` | Compile |
| `cargo check` | Check without compile |
| `cargo test` | Run tests |
| `cargo clippy` | Lint |
| `cargo fmt` | Format |
| `cargo doc` | Generate docs |
| `cargo publish` | Publish to crates.io |
| `cargo update` | Update dependencies |
| `cargo outdated` | Show outdated deps |
| `cargo tree` | Show dependency tree |
| `cargo audit` | Security audit |

## Makefile

```makefile
.PHONY: build test lint format check release

build:
	cargo build

release:
	cargo build --release

test:
	cargo test --all-features

lint:
	cargo clippy --all-features -- -D warnings

format:
	cargo fmt

format-check:
	cargo fmt --check

check:
	cargo check --all-features

audit:
	cargo audit

quality: format-check lint test audit
```
