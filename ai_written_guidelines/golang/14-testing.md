# Testing

## Basic tests

```go
// math.go
func Add(a, b int) int {
    return a + b
}

// math_test.go
package main

import "testing"

func TestAdd(t *testing.T) {
    result := Add(2, 3)
    expected := 5
    if result != expected {
        t.Errorf("Add(2,3) = %d; want %d", result, expected)
    }
}
```

## Table-driven tests

```go
func TestDivide(t *testing.T) {
    tests := []struct {
        name     string
        a, b     int
        expected int
        wantErr  bool
    }{
        {name: "normal", a: 10, b: 2, expected: 5, wantErr: false},
        {name: "by zero", a: 5, b: 0, expected: 0, wantErr: true},
        {name: "negative", a: -6, b: 3, expected: -2, wantErr: false},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result, err := Divide(tt.a, tt.b)
            if tt.wantErr && err == nil {
                t.Error("expected error")
            }
            if !tt.wantErr && result != tt.expected {
                t.Errorf("got %d, want %d", result, tt.expected)
            }
        })
    }
}
```

## Test helpers

```go
func TestConfig(t *testing.T) {
    // Create temp file
    tmpDir := t.TempDir()
    cfgPath := filepath.Join(tmpDir, "config.yaml")
    os.WriteFile(cfgPath, []byte("port: 8080\n"), 0644)

    cfg, err := LoadConfig(cfgPath)
    if err != nil {
        t.Fatal(err)
    }
    if cfg.Port != 8080 {
        t.Errorf("port = %d; want 8080", cfg.Port)
    }
}
```

## Subtests

```go
func TestService(t *testing.T) {
    t.Run("start", func(t *testing.T) {
        svc := NewService()
        if err := svc.Start(); err != nil {
            t.Fatal(err)
        }
    })

    t.Run("stop", func(t *testing.T) {
        svc := NewService()
        svc.Start()
        if err := svc.Stop(); err != nil {
            t.Fatal(err)
        }
    })
}
```

## Mocking

```go
// Interface
type Runner interface {
    Run(cmd string) (string, error)
}

// Mock
type MockRunner struct {
    RunFunc func(cmd string) (string, error)
}

func (m *MockRunner) Run(cmd string) (string, error) {
    if m.RunFunc != nil {
        return m.RunFunc(cmd)
    }
    return "", nil
}

func TestDeploy(t *testing.T) {
    mock := &MockRunner{
        RunFunc: func(cmd string) (string, error) {
            return "success", nil
        },
    }

    d := &Deployer{Runner: mock}
    if err := d.Deploy("production"); err != nil {
        t.Fatal(err)
    }
}
```

## Test coverage

```bash
go test -v -cover ./...
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out     # open in browser
go tool cover -func=coverage.out     # per-function
```

## Benchmarks

```go
func BenchmarkParseConfig(b *testing.B) {
    for i := 0; i < b.N; i++ {
        ParseConfig("testdata/config.yaml")
    }
}
```

```bash
go test -bench=. -benchmem
go test -bench=. -benchtime=10s
```

## Fuzzing (Go 1.18+)

```go
func FuzzParsePort(f *testing.F) {
    f.Add("8080")
    f.Add("invalid")
    f.Fuzz(func(t *testing.T, input string) {
        port, err := ParsePort(input)
        if err == nil {
            if port < 1 || port > 65535 {
                t.Errorf("invalid port: %d", port)
            }
        }
    })
}
```

## Race detection

```bash
go test -race ./...
```

## Running tests

```bash
go test ./...                          # all packages
go test -v ./...                       # verbose
go test -run TestAdd                   # specific test
go test -run TestAdd/negative          # subtest
go test -count=1 ./...                 # disable cache
go test -short ./...                   # skip long tests
```

## Test file conventions

```go
// Files must be named *_test.go
// Tests:     func TestXxx(t *testing.T)
// Benchmarks: func BenchmarkXxx(b *testing.B)
// Examples:  func ExampleXxx()
// Fuzz:      func FuzzXxx(f *testing.F)
```
