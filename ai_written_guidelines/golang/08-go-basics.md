# Go Basics

## Structure

```go
package main

import (
    "fmt"
    "os"
)

func main() {
    fmt.Println("Hello from Go")
    os.Exit(0)
}
```

## Types

```go
// Basic types
bool
string
int, int8, int16, int32, int64
uint, uint8, uint16, uint32, uint64
float32, float64
byte       // alias for uint8
rune       // alias for int32 (Unicode code point)

// Zero values
var i int       // 0
var f float64   // 0.0
var s string    // ""
var b bool      // false
var p *int      // nil
```

## Variables

```go
var name string = "Alice"
var count = 10          // type inference
port := 8080            // short declaration (inside functions)
var x, y int = 1, 2     // multiple

// Constants
const MaxRetries = 3
const Version = "1.0.0"
```

## Control flow

```go
// if / else
if x > 0 {
    fmt.Println("positive")
} else if x == 0 {
    fmt.Println("zero")
} else {
    fmt.Println("negative")
}

// if with statement
if err := doSomething(); err != nil {
    return err
}

// switch
switch status {
case 200:
    fmt.Println("OK")
case 404:
    fmt.Println("Not Found")
default:
    fmt.Println("Unknown")
}

// switch with no expression (clean if-else chain)
switch {
case x > 0:
    fmt.Println("positive")
case x < 0:
    fmt.Println("negative")
}

// for (only loop construct)
for i := 0; i < 10; i++ { }
for condition { }           // while
for { }                     // infinite

// range
for i, v := range items { }
for k, v := range config { }
for _, v := range values { }  // skip index
```

## Functions

```go
func add(a, b int) int {
    return a + b
}

// Multiple return values
func divide(a, b int) (int, error) {
    if b == 0 {
        return 0, fmt.Errorf("division by zero")
    }
    return a / b, nil
}

// Named return values
func stats(values []int) (min, max int) {
    min, max = values[0], values[0]
    for _, v := range values {
        if v < min { min = v }
        if v > max { max = v }
    }
    return  // naked return
}

// Variadic
func sum(nums ...int) int {
    total := 0
    for _, n := range nums { total += n }
    return total
}

// Function as value
var fn func(int, int) int = add

// Closure
func counter() func() int {
    i := 0
    return func() int {
        i++
        return i
    }
}
```

## Defer

```go
func readFile(path string) error {
    f, err := os.Open(path)
    if err != nil {
        return err
    }
    defer f.Close()  // runs when function returns
    // ... read ...
}

// Deferred functions run in LIFO order
defer fmt.Println("first")
defer fmt.Println("second")
// prints "second" then "first"
```

## Pointers

```go
x := 42
p := &x
*p = 10
fmt.Println(x)  // 10

func increment(p *int) {
    *p++
}
```

## Slices

```go
s := []int{1, 2, 3}
s = append(s, 4)
s = append(s, 5, 6)

make([]int, 5)           // len=5, cap=5
make([]int, 0, 5)        // len=0, cap=5

s[1:3]                   // sub-slice [2, 3]
copy(dst, src)           // copy elements
```

## Maps

```go
config := map[string]int{
    "port":    8080,
    "timeout": 30,
}

config["debug"] = 1

if v, ok := config["port"]; ok {
    fmt.Println(v)
}

delete(config, "debug")

for k, v := range config { }
```

## Structs

```go
type Config struct {
    Host    string
    Port    int
    Timeout int
}

cfg := Config{
    Host:    "localhost",
    Port:    8080,
    Timeout: 30,
}

cfg.Port = 9000
```

## Packages

```go
// src/myapp/config.go
package config

var DefaultPort = 8080

func Load(path string) (*Config, error) {
    // ...
}

// Import
import "myapp/config"
fmt.Println(config.DefaultPort)
```
