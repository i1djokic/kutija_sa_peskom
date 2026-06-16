# Rust Basics

## Structure

```rust
fn main() {
    println!("Hello from Rust");
}
```

## Types

```rust
// Scalar types
let i: i32 = 42;          // i8, i16, i32, i64, i128, isize
let u: u32 = 42;          // u8, u16, u32, u64, u128, usize
let f: f64 = 3.14;        // f32, f64
let b: bool = true;
let c: char = 'A';

// Compound types
let t: (i32, f64) = (42, 3.14);
let a: [i32; 3] = [1, 2, 3];

// String types
let s: String = String::from("hello");
let s: &str = "hello";    // string slice

// Type inference
let x = 42;
let y = 3.14;
```

## Variables

```rust
let x = 5;                 // immutable
let mut y = 10;            // mutable
y += 5;

// Shadowing
let x = 5;
let x = x + 1;             // shadows previous x

// Constants
const MAX_RETRIES: u32 = 3;
const VERSION: &str = "1.0.0";
```

## Control flow

```rust
// if / else
if x > 0 {
    println!("positive");
} else if x == 0 {
    println!("zero");
} else {
    println!("negative");
}

// if as expression
let status = if x > 0 { "ok" } else { "error" };

// loop
loop {
    break;
}

// while
while condition {
    // ...
}

// for
for i in 0..10 { }              // 0..9
for i in 0..=10 { }             // 0..10
for item in &items { }
for (i, item) in items.iter().enumerate() { }
```

## Pattern matching

```rust
// match
match status_code {
    200 => println!("OK"),
    404 => println!("Not Found"),
    code if code >= 500 => println!("Server error"),
    _ => println!("Unknown"),
}

// match as expression
let description = match code {
    200 => "ok",
    404 => "not found",
    _ => "unknown",
};

// if let
if let Some(value) = optional {
    println!("Got: {}", value);
}

// while let
while let Some(line) = reader.next_line() {
    println!("{}", line);
}

// let else
let Some(value) = optional else {
    return;
};
```

## Functions

```rust
fn add(x: i32, y: i32) -> i32 {
    x + y  // expression (no semicolon = return)
}

fn greet(name: &str) -> String {
    format!("Hello, {}!", name)
}

fn print(s: &str) {
    println!("{}", s);
}

// Generic
fn first<T>(list: &[T]) -> &T {
    &list[0]
}
```

## Closures

```rust
let square = |x: i32| -> i32 { x * x };
let add = |a, b| a + b;

// Capture by reference/move
let name = String::from("Alice");
let greet = || println!("Hello {}", name);   // borrow
let move_greet = move || println!("{}", name); // move
```

## Vectors

```rust
let mut v: Vec<i32> = Vec::new();
v.push(1);
v.push(2);
v.pop();

let v = vec![1, 2, 3];

for item in &v { }
for item in v.iter() { }
for item in v.iter_mut() { *item *= 2; }
```

## HashMap

```rust
use std::collections::HashMap;

let mut config = HashMap::new();
config.insert(String::from("host"), String::from("localhost"));
config.insert(String::from("port"), String::from("8080"));

if let Some(value) = config.get("host") {
    println!("{}", value);
}

for (key, value) in &config {
    println!("{} = {}", key, value);
}
```

## Common patterns

```rust
// Builder pattern
let config = Config::builder()
    .host("localhost")
    .port(8080)
    .build();

// Result with ?
fn read_config(path: &str) -> Result<Config, Box<dyn std::error::Error>> {
    let content = std::fs::read_to_string(path)?;
    let cfg: Config = serde_yaml::from_str(&content)?;
    Ok(cfg)
}
```
