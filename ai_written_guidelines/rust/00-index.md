# Rust Programming & Automation Guide

A curated reference for Rust essentials and programming principles with a focus on **systems programming, automation tooling, and performance-critical infrastructure**.

---

## Rust Essentials

| # | Topic | Description |
|---|-------|-------------|
| 1 | [Rust Basics](12-rust-basics.md) | Syntax, types, control flow, pattern matching |
| 2 | [Ownership & Borrowing](10-ownership.md) | Ownership, references, lifetimes, rules |
| 3 | [Structs, Enums & Traits](13-structs-traits.md) | Structs, enums, pattern matching, traits, generics |
| 4 | [Error Handling](06-error-handling.md) | `Result`, `Option`, `?`, `thiserror`, `anyhow` |
| 5 | [File I/O](07-file-io.md) | `std::fs`, Path, reading/writing, serde |
| 6 | [Date & Time](05-datetime.md) | `chrono`, durations, formatting, tokio timers |

## DevOps & Automation

| # | Topic | Description |
|---|-------|-------------|
| 7 | [Build Tools & Cargo](01-build-tools.md) | Cargo, Cargo.toml, features, workspaces, profiles |
| 8 | [Logging](08-logging.md) | `log`/`env_logger`, `tracing`, structured logging |
| 9 | [Subprocess & System](14-subprocess.md) | `std::process`, tokio process, signals |
| 10 | [CLI Tools](02-cli-tools.md) | `clap`, `structopt`, env vars, exit codes |
| 11 | [Testing](15-testing.md) | `cargo test`, unit/integration tests, doc tests, benchmarks |
| 12 | [Concurrency & Async](04-concurrency.md) | `std::thread`, `tokio`, async/await, channels |
| 13 | [Networking](09-networking.md) | `reqwest`, `tokio`, TCP/UDP, HTTP clients |
| 14 | [Code Quality](03-code-quality.md) | `clippy`, `rustfmt`, `cargo check`, `cargo deny` |

## Programming Principles

| # | Topic | Description |
|---|-------|-------------|
| 15 | [Programming Principles](11-programming-principles.md) | Ownership, SOLID, DRY, KISS, borrow checker ethos |

---

> **Purpose:** Quick-reference for developers working on Rust-based CLI tools, network services, and automation infrastructure.
