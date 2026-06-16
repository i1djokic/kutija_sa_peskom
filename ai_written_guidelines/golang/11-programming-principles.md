# Programming Principles

## Idiomatic Go principles

### Composition over Inheritance

Go has no classes or inheritance. Use composition.

```go
// Embedding (composition)
type Service struct {
    Logger           // embedded
    Name    string
    HealthChecker    // embedded
}

s := Service{Name: "web"}
s.Log("started")     // method from Logger
s.Check()            // method from HealthChecker
```

### Accept interfaces, return structs

```go
// Good: accept interface
func Process(runner Runner, cmd string) error {
    out, err := runner.Run(cmd)
    // ...
}

// Good: return concrete type
func NewService() *Service {
    return &Service{Name: "web"}
}
```

### Zero values should be useful

```go
// Good: zero value is ready to use
type Config struct {
    Host    string  // "" default
    Port    int     // 0 default (invalid, but explicit)
    Timeout int     // 0 default
}

// Better: proper defaults
func NewConfig() *Config {
    return &Config{
        Host:    "localhost",
        Port:    8080,
        Timeout: 30,
    }
}
```

## SOLID in Go

| Principle | Go Practice |
|-----------|-------------|
| **S**ingle Responsibility | One package = one purpose |
| **O**pen/Closed | Interfaces for extension |
| **L**iskov Substitution | Interface satisfaction is implicit |
| **I**nterface Segregation | Small interfaces (1-3 methods) |
| **D**ependency Inversion | Accept interfaces, inject dependencies |

## DRY (Don't Repeat Yourself)

```go
// Bad
func startWeb() { exec.Command("systemctl", "start", "web").Run() }
func stopWeb()  { exec.Command("systemctl", "stop", "web").Run() }

// Good
func serviceAction(action, name string) error {
    return exec.Command("systemctl", action, name).Run()
}
```

## KISS (Keep It Simple, Stupid)

- Flat package structure over deep nesting
- Prefer `if err != nil` over try-catch patterns
- Simple `for` loops over complex functional chains
- `interface{}` / `any` is rarely the right answer

## YAGNI (You Ain't Gonna Need It)

```go
// Don't write this until you need it
type FlexibleConfig[T any] struct { ... }
```

## Fail Fast

```go
func deploy(env, version string) error {
    if env == "" {
        return errors.New("env is required")
    }
    if version == "" {
        return errors.New("version is required")
    }
    // proceed...
}
```

## Idempotency

```go
func ensureDirectory(path string) error {
    return os.MkdirAll(path, 0755)
    // safe to call multiple times
}

func ensureUser(username string) (bool, error) {
    cmd := exec.Command("id", username)
    if err := cmd.Run(); err == nil {
        return false, nil  // already exists
    }
    cmd = exec.Command("useradd", username)
    if err := cmd.Run(); err != nil {
        return false, fmt.Errorf("creating user: %w", err)
    }
    return true, nil
}
```

## Go proverbs

- Don't communicate by sharing memory; share memory by communicating.
- Concurrency is not parallelism.
- Channels orchestrate; mutexes serialize.
- The bigger the interface, the weaker the abstraction.
- Errors are values.
- Package names are lowercase, single word.
- `init()` is the last resort.
- `go vet` before `git commit`.
- Clear is better than clever.
