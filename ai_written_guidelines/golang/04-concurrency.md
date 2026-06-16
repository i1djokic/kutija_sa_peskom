# Concurrency

## Goroutines

```go
func worker(id int) {
    fmt.Printf("Worker %d started\n", id)
}

go worker(1)          // start goroutine
go func() {           // anonymous goroutine
    fmt.Println("done")
}()

// Wait for completion
var wg sync.WaitGroup
for i := 0; i < 5; i++ {
    wg.Add(1)
    go func(id int) {
        defer wg.Done()
        worker(id)
    }(i)
}
wg.Wait()
```

## Channels

```go
// Unbuffered channel (synchronous)
ch := make(chan int)
go func() { ch <- 42 }()
value := <-ch

// Buffered channel
ch := make(chan string, 10)
ch <- "job1"
ch <- "job2"
close(ch)

// Range over channel
for msg := range ch {
    fmt.Println(msg)
}

// Select (wait on multiple channels)
select {
case msg := <-ch1:
    fmt.Println(msg)
case msg := <-ch2:
    fmt.Println(msg)
case <-time.After(1 * time.Second):
    fmt.Println("timeout")
default:
    fmt.Println("no message ready")
}
```

### Worker pool

```go
func worker(id int, jobs <-chan int, results chan<- int) {
    for job := range jobs {
        results <- job * 2
    }
}

jobs := make(chan int, 100)
results := make(chan int, 100)

// Start workers
for w := 0; w < 3; w++ {
    go worker(w, jobs, results)
}

// Send jobs
for j := 0; j < 10; j++ {
    jobs <- j
}
close(jobs)

// Collect results
for r := 0; r < 10; r++ {
    <-results
}
```

## sync.Mutex

```go
type Counter struct {
    mu    sync.Mutex
    value int
}

func (c *Counter) Increment() {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.value++
}

func (c *Counter) Value() int {
    c.mu.Lock()
    defer c.mu.Unlock()
    return c.value
}
```

## sync.RWMutex

```go
type Cache struct {
    mu   sync.RWMutex
    data map[string]string
}

func (c *Cache) Get(key string) (string, bool) {
    c.mu.RLock()
    defer c.mu.RUnlock()
    v, ok := c.data[key]
    return v, ok
}

func (c *Cache) Set(key, value string) {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.data[key] = value
}
```

## sync.Once

```go
var (
    config *Config
    once   sync.Once
)

func GetConfig() *Config {
    once.Do(func() {
        config = loadConfig()
    })
    return config
}
```

## errgroup (common concurrency pattern)

```go
import "golang.org/x/sync/errgroup"

g, ctx := errgroup.WithContext(context.Background())

for _, url := range urls {
    url := url
    g.Go(func() error {
        resp, err := http.Get(url)
        if err != nil {
            return err
        }
        defer resp.Body.Close()
        // process...
        return nil
    })
}

if err := g.Wait(); err != nil {
    log.Fatal(err)
}
```

## Context

```go
import "context"

ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()

result, err := someOperation(ctx)

// Check cancellation
select {
case <-ctx.Done():
    return ctx.Err()
default:
}

// Context values (for request-scoped data)
ctx = context.WithValue(ctx, "request_id", "abc123")
```

## Concurrency patterns

```go
// Fan-out / Fan-in
func fanOut(input <-chan int, workers int) []<-chan int {
    channels := make([]<-chan int, workers)
    for i := 0; i < workers; i++ {
        ch := make(chan int)
        channels[i] = ch
        go func() {
            for v := range input {
                ch <- process(v)
            }
            close(ch)
        }()
    }
    return channels
}

func fanIn(channels ...<-chan int) <-chan int {
    out := make(chan int)
    var wg sync.WaitGroup
    for _, ch := range channels {
        wg.Add(1)
        go func(c <-chan int) {
            defer wg.Done()
            for v := range c {
                out <- v
            }
        }(ch)
    }
    go func() {
        wg.Wait()
        close(out)
    }()
    return out
}
```

## When to use what

| Tool | Best for |
|------|----------|
| Goroutines | Lightweight concurrent execution |
| Channels | Communication between goroutines |
| `sync.Mutex` | Protecting shared state |
| `sync.WaitGroup` | Waiting for goroutine completion |
| `sync.Once` | Lazy singleton initialization |
| `errgroup` | Group of goroutines with error handling |
| `context` | Cancellation, timeouts, deadlines |
