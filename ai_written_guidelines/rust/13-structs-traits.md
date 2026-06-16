# Structs, Enums & Traits

## Structs

```rust
struct Service {
    name: String,
    host: String,
    port: u16,
    running: bool,
}

// Create
let svc = Service {
    name: String::from("web"),
    host: String::from("localhost"),
    port: 8080,
    running: false,
};

// Mutable access
let mut svc = Service { name: "web".into(), .. };
svc.running = true;

// Field init shorthand
let name = String::from("web");
let svc = Service { name, host: "localhost".into(), port: 8080, running: false };

// Struct update syntax
let svc2 = Service { port: 9090, ..svc };  // move remaining fields
```

### Methods

```rust
impl Service {
    fn new(name: &str, host: &str, port: u16) -> Self {
        Self {
            name: name.to_string(),
            host: host.to_string(),
            port,
            running: false,
        }
    }

    fn start(&mut self) {
        self.running = true;
        println!("{} started on {}:{}", self.name, self.host, self.port);
    }

    fn stop(&mut self) {
        self.running = false;
    }

    fn is_running(&self) -> bool {
        self.running
    }
}
```

## Enums

```rust
enum Status {
    Ok,
    Warning(String),
    Error { code: i32, message: String },
}

// Usage
let s = Status::Ok;
let s = Status::Warning("disk full".into());
let s = Status::Error { code: 500, message: "timeout".into() };

// Match
match status {
    Status::Ok => println!("All good"),
    Status::Warning(msg) => println!("Warning: {}", msg),
    Status::Error { code, message } => {
        println!("Error {}: {}", code, message);
    }
}
```

### Common enums

```rust
// Option
let some: Option<i32> = Some(42);
let none: Option<i32> = None;

match some {
    Some(v) => println!("Value: {}", v),
    None => println!("No value"),
}

// Result
let ok: Result<i32, String> = Ok(42);
let err: Result<i32, String> = Err("failed".into());
```

## Traits

```rust
trait Runner {
    fn run(&self, command: &str) -> Result<String, String>;
}

struct LocalRunner;

impl Runner for LocalRunner {
    fn run(&self, command: &str) -> Result<String, String> {
        // execute locally
        Ok("output".into())
    }
}

struct SSHRunner {
    host: String,
    user: String,
}

impl Runner for SSHRunner {
    fn run(&self, command: &str) -> Result<String, String> {
        // execute via SSH
        Ok("remote output".into())
    }
}

// Trait as parameter
fn execute(runner: &impl Runner, cmd: &str) {
    match runner.run(cmd) {
        Ok(out) => println!("{}", out),
        Err(e) => eprintln!("Error: {}", e),
    }
}

// Trait bound syntax
fn execute<T: Runner>(runner: &T, cmd: &str) { }
```

### Derive macros

```rust
#[derive(Debug, Clone, PartialEq, Eq)]
struct Config {
    host: String,
    port: u16,
}

// Commonly derived traits:
// Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Default
```

### Default trait

```rust
#[derive(Default)]
struct Config {
    host: String,       // defaults to ""
    port: u16,          // defaults to 0
    debug: bool,        // defaults to false
}

let cfg = Config::default();
```

### From/Into

```rust
impl From<&str> for Status {
    fn from(s: &str) -> Self {
        match s {
            "ok" => Status::Ok,
            msg => Status::Warning(msg.to_string()),
        }
    }
}

let status: Status = "disk full".into();
```

## Generics

```rust
struct Stack<T> {
    items: Vec<T>,
}

impl<T> Stack<T> {
    fn new() -> Self {
        Self { items: Vec::new() }
    }

    fn push(&mut self, item: T) {
        self.items.push(item);
    }

    fn pop(&mut self) -> Option<T> {
        self.items.pop()
    }
}

// Generic function
fn first<T: Clone>(list: &[T]) -> T {
    list[0].clone()
}
```
