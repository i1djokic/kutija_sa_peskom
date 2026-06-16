# Ownership & Borrowing

## Ownership rules

1. Each value has exactly one owner
2. When the owner goes out of scope, the value is dropped
3. References do not take ownership

## Move semantics

```rust
let s1 = String::from("hello");
let s2 = s1;            // s1 is MOVED to s2
// println!("{}", s1);  // ERROR: s1 is no longer valid

// Clone (deep copy)
let s1 = String::from("hello");
let s2 = s1.clone();    // explicitly deep copy
println!("{}", s1);     // OK

// Copy types (stack-only)
let x = 42;
let y = x;              // COPY (implements Copy trait)
println!("{}", x);      // OK
```

## Borrowing

```rust
// Immutable reference (&)
fn length(s: &String) -> usize {
    s.len()
}

let s = String::from("hello");
let len = length(&s);   // borrow, not move
println!("{}", s);      // OK: s still owned here

// Mutable reference (&mut)
fn append_world(s: &mut String) {
    s.push_str(" world");
}

let mut s = String::from("hello");
append_world(&mut s);
println!("{}", s);      // "hello world"
```

## Borrowing rules

```rust
// Rule 1: Many immutable references OR one mutable reference
let mut s = String::from("hello");

let r1 = &s;            // OK
let r2 = &s;            // OK
// let r3 = &mut s;     // ERROR: already borrowed immutably
println!("{} {}", r1, r2);

let r3 = &mut s;        // OK: no immutable references in use
r3.push_str(" world");
```

## Lifetimes

```rust
// Explicit lifetime annotation
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() { x } else { y }
}

// Lifetime in structs
struct Config<'a> {
    host: &'a str,
    port: u16,
}

// Static lifetime
let s: &'static str = "lives forever";

// Lifetime elision (compiler infers):
// 1. Each input reference gets its own lifetime
// 2. If only one input, output gets that lifetime
fn first_word(s: &str) -> &str {  // elided
    &s[..s.find(' ').unwrap_or(s.len())]
}
```

## Common patterns

```rust
// Take ownership, return modified
fn uppercase(mut s: String) -> String {
    s.make_ascii_uppercase();
    s
}

// Borrow mutably and modify
fn add_port(config: &mut Config, port: u16) {
    config.port = port;
}

// Iterate without consuming
let items = vec![1, 2, 3];
for item in &items {            // borrows
    println!("{}", item);
}
println!("{:?}", items);        // still valid
```

## Smart pointers

```rust
// Box (heap allocation)
let b = Box::new(42);

// Rc (reference counting, single-threaded)
use std::rc::Rc;
let shared = Rc::new(42);
let a = Rc::clone(&shared);
let b = Rc::clone(&shared);

// RefCell (interior mutability)
use std::cell::RefCell;
let data = RefCell::new(42);
*data.borrow_mut() += 1;
```
