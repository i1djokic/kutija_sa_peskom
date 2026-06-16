# Programming Principles

## Ownership-driven design

Rust's ownership model is not just a memory management feature — it's a design philosophy.

```rust
// Clear ownership: Config owns all its data
struct Config {
    host: String,
    port: u16,
}

// Function signals whether it borrows or takes ownership
fn print_config(cfg: &Config) {  // borrow (read-only)
    println!("{}:{}", cfg.host, cfg.port);
}

fn consume_config(cfg: Config) {  // takes ownership
    // cfg is dropped here
}
```

## SOLID in Rust

| Letter | Principle | Rust Practice |
|--------|-----------|---------------|
| **S** | Single Responsibility | One struct/function = one purpose |
| **O** | Open/Closed | Traits for extension |
| **L** | Liskov Substitution | Trait bounds ensure substitutability |
| **I** | Interface Segregation | Small, focused traits |
| **D** | Dependency Inversion | Accept trait objects, inject dependencies |

### Dependency Injection

```rust
trait Notifier {
    fn send(&self, msg: &str) -> Result<()>;
}

struct EmailNotifier;
impl Notifier for EmailNotifier { /* ... */ }

struct SlackNotifier;
impl Notifier for SlackNotifier { /* ... */ }

struct Deployer {
    notifier: Box<dyn Notifier>,
}

impl Deployer {
    fn deploy(&self, env: &str) -> Result<()> {
        // ... deploy logic ...
        self.notifier.send(&format!("Deployed to {}", env))
    }
}
```

## DRY (Don't Repeat Yourself)

```rust
// Bad: duplicated
fn start_service(name: &str) -> Result<()> {
    Command::new("systemctl").arg("start").arg(name).run()?;
    Ok(())
}
fn stop_service(name: &str) -> Result<()> {
    Command::new("systemctl").arg("stop").arg(name).run()?;
    Ok(())
}

// Good: single function
fn service_ctl(action: &str, name: &str) -> Result<()> {
    Command::new("systemctl").arg(action).arg(name).run()?;
    Ok(())
}
```

## KISS (Keep It Simple, Stupid)

- Prefer `Vec<T>` over custom container types
- Prefer simple enums over deep type hierarchies
- One function, one responsibility
- Avoid macros where regular functions suffice
- Avoid complex generics unless they provide clear value

## YAGNI (You Ain't Gonna Need It)

```rust
// Don't abstract until you have at least 3 concrete use cases
// Don't add generic parameters you don't use
struct Config {
    host: String,
    port: u16,
    // Don't add `phantom: PhantomData<T>` "just in case"
}
```

## Fail Fast + Typed Errors

```rust
fn deploy(env: &str, version: &str) -> Result<(), DeployError> {
    if env.is_empty() {
        return Err(DeployError::InvalidEnv("empty env".into()));
    }
    if !version.starts_with('v') {
        return Err(DeployError::InvalidVersion(version.into()));
    }
    // proceed...
}
```

## Idempotency

```rust
fn ensure_directory(path: &Path) -> Result<()> {
    fs::create_dir_all(path)?;  // safe to call multiple times
    Ok(())
}

fn ensure_user(name: &str) -> Result<bool> {
    let output = Command::new("id").arg(name).output()?;
    if output.status.success() {
        return Ok(false);  // already exists
    }
    Command::new("useradd").arg(name).run()?;
    Ok(true)
}
```

## Rust-specific principles

| Principle | Practice |
|-----------|----------|
| Ownership clarity | Every value has one owner |
| Mutability control | `mut` is explicit |
| Error types | Use `Result`, not exceptions |
| Zero-cost abstractions | Abstraction with no runtime cost |
| Fearless concurrency | Compiler prevents data races |
| Expressivity | Enums, pattern matching, traits |
| Immutability by default | Everything is `const` unless `mut` |

## Summary

```
Ownership  → Memory safety without GC
SOLID      → Maintainable abstractions
DRY        → No duplication
KISS       → Simple over clever
YAGNI      → Only what you need
Fail Fast  → Validate early, fail with good errors
Idempotency → Safe to retry
Typed errors → Let the compiler help
Immutable first → Easier to reason about
```
