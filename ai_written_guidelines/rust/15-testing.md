# Testing

## Basic tests

```rust
// src/lib.rs
pub fn add(a: i32, b: i32) -> i32 {
    a + b
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_add() {
        assert_eq!(add(2, 3), 5);
        assert_ne!(add(2, 3), 0);
    }

    #[test]
    #[should_panic(expected = "divide by zero")]
    fn test_divide_by_zero() {
        divide(10, 0);
    }
}
```

## Result in tests

```rust
#[test]
fn test_read_config() -> Result<(), Box<dyn std::error::Error>> {
    let cfg = read_config("test.yaml")?;
    assert_eq!(cfg.port, 8080);
    Ok(())
}
```

## Integration tests

```rust
// tests/integration_test.rs
use myapp::config;

#[test]
fn test_config_loading() {
    let cfg = config::load("tests/fixtures/config.yaml").unwrap();
    assert_eq!(cfg.host, "localhost");
}
```

## Test fixtures

```rust
#[test]
fn test_with_temp_dir() {
    let dir = tempfile::TempDir::new().unwrap();
    let config_path = dir.path().join("config.yaml");
    std::fs::write(&config_path, "host: localhost\nport: 8080\n").unwrap();

    let cfg = load_config(config_path.to_str().unwrap()).unwrap();
    assert_eq!(cfg.port, 8080);
}
```

## Doc tests

```rust
/// Adds two numbers together.
///
/// # Examples
///
/// ```
/// use myapp::add;
///
/// assert_eq!(add(2, 3), 5);
/// ```
pub fn add(a: i32, b: i32) -> i32 {
    a + b
}
```

```bash
cargo test --doc     # run only doc tests
```

## Test organization

```rust
// Inline tests
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn unit_test() { }

    #[test]
    fn another_test() { }
}

// Separate test files
// tests/
//   integration_test.rs
//   cli_tests.rs
//   fixtures/
//     config.yaml
```

## Mocking

```rust
// Trait to mock
trait HttpClient {
    fn get(&self, url: &str) -> Result<String, Error>;
}

struct RealClient;

impl HttpClient for RealClient {
    fn get(&self, url: &str) -> Result<String, Error> {
        reqwest::blocking::get(url)?.text()
    }
}

// Mock
struct MockClient {
    response: String,
}

impl HttpClient for MockClient {
    fn get(&self, _url: &str) -> Result<String, Error> {
        Ok(self.response.clone())
    }
}

#[test]
fn test_fetch_config() {
    let client = MockClient {
        response: r#"{"port": 8080}"#.into(),
    };
    let cfg = fetch_config(&client, "http://example.com").unwrap();
    assert_eq!(cfg.port, 8080);
}
```

## Benchmarks

```rust
#![feature(test)]

extern crate test;

#[cfg(test)]
mod benches {
    use super::*;
    use test::Bencher;

    #[bench]
    fn bench_parse_config(b: &mut Bencher) {
        b.iter(|| {
            parse_config("bench_data.yaml")
        });
    }
}
```

```bash
# Nightly only
cargo bench
```

### criterion (stable Rust)

```toml
[dev-dependencies]
criterion = "0.5"

[[bench]]
name = "parse"
harness = false
```

```rust
// benches/parse.rs
use criterion::{black_box, criterion_group, criterion_main, Criterion};

fn bench_parse(c: &mut Criterion) {
    c.bench_function("parse config", |b| {
        b.iter(|| parse_config(black_box("bench.yaml")))
    });
}

criterion_group!(benches, bench_parse);
criterion_main!(benches);
```

## Running tests

```bash
cargo test                        # all tests
cargo test test_add               # filter by name
cargo test -- --nocapture         # show stdout
cargo test -- --test-threads=1    # single-threaded
cargo test --release              # release mode
cargo test --lib                  # only unit tests
cargo test --test integration     # only integration tests
cargo test --doc                  # only doc tests
cargo test -- --ignored           # only ignored tests
```
