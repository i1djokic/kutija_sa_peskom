# Error Handling

## The error interface

```go
type error interface {
    Error() string
}
```

## Basic pattern

```go
func readConfig(path string) (*Config, error) {
    f, err := os.Open(path)
    if err != nil {
        return nil, fmt.Errorf("opening config: %w", err)
    }
    defer f.Close()
    // ...
    return cfg, nil
}

cfg, err := readConfig("config.yaml")
if err != nil {
    log.Fatalf("Error: %v", err)
}
```

## Sentinel errors

```go
var (
    ErrNotFound   = errors.New("not found")
    ErrPermission = errors.New("permission denied")
    ErrTimeout    = errors.New("operation timed out")
)

func findService(name string) (*Service, error) {
    // ...
    return nil, ErrNotFound
}

if errors.Is(err, ErrNotFound) {
    // handle not found
}
```

## Custom error types

```go
type ConfigError struct {
    Path string
    Err  error
}

func (e *ConfigError) Error() string {
    return fmt.Sprintf("config error in %s: %v", e.Path, e.Err)
}

func (e *ConfigError) Unwrap() error {
    return e.Err
}

// Usage
return nil, &ConfigError{Path: path, Err: err}

// Check
var cfgErr *ConfigError
if errors.As(err, &cfgErr) {
    fmt.Println("Bad config:", cfgErr.Path)
}
```

## Wrapping errors

```go
// Wrap with context
if err != nil {
    return fmt.Errorf("reading config: %w", err)
}

// Unwrap
err := errors.Unwrap(wrappedErr)

// Check
errors.Is(err, os.ErrNotExist)
errors.As(err, &netErr)
```

## panic / recover

```go
// panic: unexpected, unrecoverable
if s == nil {
    panic("service is nil")
}

// recover: catch panic (only useful in deferred functions)
func safeCall() (err error) {
    defer func() {
        if r := recover(); r != nil {
            err = fmt.Errorf("panic: %v", r)
        }
    }()
    riskyOperation()
    return nil
}
```

## Defer + error pattern

```go
func readFile(path string) (data []byte, err error) {
    f, err := os.Open(path)
    if err != nil {
        return nil, err
    }
    defer func() {
        if cerr := f.Close(); cerr != nil && err == nil {
            err = cerr
        }
    }()
    return io.ReadAll(f)
}
```

## Best practices

- Always check errors (don't use `_` to ignore)
- Wrap errors with context using `%w`
- Use `errors.Is` / `errors.As` for inspection
- Define sentinel errors with `var ErrX = errors.New(...)`
- Only panic for truly unrecoverable states (startup, nil deref)
- Return early, nest not
- Use `log.Fatal` in main, return errors from libraries

```go
// Good
if err != nil {
    return fmt.Errorf("deploy %s: %w", env, err)
}

// Bad
result, _ := doSomething()
```
