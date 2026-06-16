# Subprocess & System Automation

## os/exec

```go
import "os/exec"

// Simple command
out, err := exec.Command("ls", "-la", "/tmp").Output()
if err != nil {
    log.Fatal(err)
}
fmt.Println(string(out))

// Combined output (stdout + stderr)
out, err := exec.Command("systemctl", "status", "nginx").CombinedOutput()
fmt.Println(string(out))
```

### Advanced command execution

```go
cmd := exec.Command("deploy.sh", "--env", "production")

// Set working directory
cmd.Dir = "/opt/myapp"

// Custom environment
cmd.Env = append(os.Environ(),
    "MYAPP_ENV=production",
    "MYAPP_DEBUG=0",
)

// Stdin/Stdout/Stderr pipes
cmd.Stdin = strings.NewReader("input data")
cmd.Stdout = os.Stdout
cmd.Stderr = os.Stderr

if err := cmd.Run(); err != nil {
    log.Fatal(err)
}
```

### Capture stdout and stderr separately

```go
var stdout, stderr bytes.Buffer
cmd := exec.Command("deploy.sh", "--env", "prod")
cmd.Stdout = &stdout
cmd.Stderr = &stderr

err := cmd.Run()
if err != nil {
    log.Printf("stderr: %s", stderr.String())
    log.Fatal(err)
}
fmt.Println(stdout.String())
```

### With context (timeout/cancellation)

```go
ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
defer cancel()

cmd := exec.CommandContext(ctx, "backup.sh", "--full")
out, err := cmd.Output()
if errors.Is(err, context.DeadlineExceeded) {
    log.Fatal("Command timed out")
}
```

### Pipe commands

```go
grep := exec.Command("grep", "error")
wc := exec.Command("wc", "-l")

wc.Stdin, _ = grep.StdoutPipe()
wc.Stdout = os.Stdout

wc.Start()
grep.Run()
wc.Wait()
```

## os/signal

```go
import "os/signal"

func main() {
    sig := make(chan os.Signal, 1)
    signal.Notify(sig, syscall.SIGTERM, syscall.SIGINT)

    <-sig  // block until signal
    fmt.Println("Shutting down...")
    cleanup()
}
```

### Graceful shutdown

```go
func main() {
    ctx, stop := signal.NotifyContext(context.Background(),
        syscall.SIGTERM, syscall.SIGINT)
    defer stop()

    server := &http.Server{Addr: ":8080"}

    go func() {
        <-ctx.Done()
        shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
        defer cancel()
        server.Shutdown(shutdownCtx)
    }()

    log.Fatal(server.ListenAndServe())
}
```

## os.Process

```go
// Start and manage a process
cmd := exec.Command("long-running-task")
cmd.Start()

// Kill
cmd.Process.Kill()

// Or
cmd.Process.Signal(syscall.SIGTERM)

// Wait
err := cmd.Wait()

// Process info
pid := cmd.Process.Pid
```

## Find and kill processes

```go
func killProcess(name string, sig os.Signal) error {
    cmd := exec.Command("pkill", "-f", name)
    return cmd.Run()
}

// By PID
func killPID(pid int, sig os.Signal) error {
    proc, err := os.FindProcess(pid)
    if err != nil {
        return err
    }
    return proc.Signal(sig)
}
```

## Environment variables

```go
import "os"

// Get with default
host := os.Getenv("HOST")
if host == "" { host = "localhost" }

// Set for subprocesses
os.Setenv("MYAPP_ENV", "production")
os.Unsetenv("TEMP_VAR")

// List all
for _, env := range os.Environ() {
    fmt.Println(env)
}

// Lookup (check if set)
if val, ok := os.LookupEnv("API_KEY"); ok {
    fmt.Println("API_KEY is set")
}
```

## Exit

```go
os.Exit(0)      // success
os.Exit(1)      // failure
// os.Exit skips deferred functions
// Use log.Fatal or return from main instead
```
