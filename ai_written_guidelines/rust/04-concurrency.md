# Concurrency & Async

## std::thread

```rust
use std::thread;
use std::time::Duration;

let handle = thread::spawn(|| {
    println!("Hello from thread");
});

handle.join().unwrap();

// With move closure
let data = vec![1, 2, 3];
let handle = thread::spawn(move || {
    println!("{:?}", data);
});
handle.join().unwrap();
```

### Thread pool (rayon)

```toml
[dependencies]
rayon = "1"
```

```rust
use rayon::prelude::*;

fn is_prime(n: u32) -> bool {
    (2..n).all(|i| n % i != 0)
}

// Automatic parallel iteration
let numbers: Vec<u32> = (0..1000).collect();
let primes: Vec<&u32> = numbers.par_iter()
    .filter(|n| is_prime(**n))
    .collect();

// Parallel fold
let sum: u32 = (0..10000).into_par_iter().sum();
```

## Channels

```rust
use std::sync::mpsc;

let (tx, rx) = mpsc::channel();

thread::spawn(move || {
    tx.send(42).unwrap();
});

let received = rx.recv().unwrap();
println!("Got: {}", received);
```

### Multiple producers

```rust
let (tx, rx) = mpsc::channel();

for i in 0..5 {
    let tx = tx.clone();
    thread::spawn(move || {
        tx.send(i).unwrap();
    });
}

for received in rx {
    println!("Got: {}", received);
}
```

## async / tokio

```toml
[dependencies]
tokio = { version = "1", features = ["full"] }
```

```rust
use tokio::time;

async fn fetch_data(url: &str) -> Result<String, reqwest::Error> {
    let resp = reqwest::get(url).await?;
    let body = resp.text().await?;
    Ok(body)
}

#[tokio::main]
async fn main() -> Result<()> {
    let result = fetch_data("https://example.com").await?;
    println!("{}", result);
    Ok(())
}
```

### Concurrent tasks

```rust
use tokio::task;

let handles: Vec<_> = (0..10).map(|i| {
    task::spawn(async move {
        // concurrent work
        i * 2
    })
}).collect();

for handle in handles {
    let result = handle.await?;
    println!("{}", result);
}
```

### tokio::join! / tokio::try_join!

```rust
async fn task1() -> Result<String> { Ok("one".into()) }
async fn task2() -> Result<String> { Ok("two".into()) }

let (r1, r2) = tokio::join!(task1(), task2());
// both complete, either success or error

let (r1, r2) = tokio::try_join!(task1(), task2())?;
// short-circuits on first error
```

### Async HTTP with reqwest

```rust
use reqwest;

async fn check_health(url: &str) -> Result<bool, reqwest::Error> {
    let client = reqwest::Client::new();
    let resp = client.get(url)
        .timeout(Duration::from_secs(5))
        .send()
        .await?;
    Ok(resp.status().is_success())
}

async fn check_many(urls: &[String]) -> Vec<bool> {
    let futures: Vec<_> = urls.iter()
        .map(|url| check_health(url))
        .collect();
    futures::future::join_all(futures).await
        .into_iter()
        .map(|r| r.unwrap_or(false))
        .collect()
}
```

## Arc<Mutex<>> (shared state)

```rust
use std::sync::{Arc, Mutex};

let counter = Arc::new(Mutex::new(0));
let mut handles = vec![];

for _ in 0..10 {
    let counter = Arc::clone(&counter);
    handles.push(thread::spawn(move || {
        let mut num = counter.lock().unwrap();
        *num += 1;
    }));
}

for handle in handles {
    handle.join().unwrap();
}

println!("Result: {}", *counter.lock().unwrap());
```

## async Mutex

```rust
use tokio::sync::Mutex;

let counter = Arc::new(Mutex::new(0));

async fn increment(counter: Arc<Mutex<i32>>) {
    let mut value = counter.lock().await;
    *value += 1;
}
```

## When to use what

| Tool | Best for |
|------|----------|
| `std::thread` | CPU-bound parallelism |
| `rayon` | Easy data parallelism |
| `tokio` | Async I/O (network, files) |
| `mpsc` | Channel communication |
| `Arc<Mutex>` | Shared mutable state (sync) |
| `tokio::sync::Mutex` | Shared mutable state (async) |
| `futures::join_all` | Many concurrent futures |
