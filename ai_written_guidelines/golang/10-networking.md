# Networking & HTTP

## HTTP client

```go
import (
    "net/http"
    "io"
)

// Basic GET
resp, err := http.Get("https://api.example.com/health")
if err != nil {
    log.Fatal(err)
}
defer resp.Body.Close()

body, _ := io.ReadAll(resp.Body)
fmt.Println(string(body))

// With timeout
client := &http.Client{
    Timeout: 10 * time.Second,
}
resp, err := client.Get("https://api.example.com/health")
```

### Advanced request

```go
req, _ := http.NewRequest("POST", "https://api.example.com/deploy", nil)
req.Header.Set("Authorization", "Bearer "+token)
req.Header.Set("Content-Type", "application/json")

resp, err := client.Do(req)
if err != nil {
    log.Fatal(err)
}
defer resp.Body.Close()

fmt.Println(resp.StatusCode)
body, _ := io.ReadAll(resp.Body)
```

### JSON client

```go
type DeployRequest struct {
    Env     string `json:"env"`
    Version string `json:"version"`
}

type DeployResponse struct {
    Status  string `json:"status"`
    JobID   string `json:"job_id"`
}

func deploy(env, version string) (*DeployResponse, error) {
    body, _ := json.Marshal(DeployRequest{Env: env, Version: version})

    resp, err := http.Post(
        "https://api.example.com/deploy",
        "application/json",
        bytes.NewReader(body),
    )
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()

    var result DeployResponse
    if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
        return nil, err
    }
    return &result, nil
}
```

## HTTP server

```go
func healthHandler(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(map[string]string{
        "status": "ok",
    })
}

func main() {
    mux := http.NewServeMux()
    mux.HandleFunc("/health", healthHandler)
    mux.HandleFunc("/deploy", deployHandler)

    server := &http.Server{
        Addr:         ":8080",
        Handler:      mux,
        ReadTimeout:  10 * time.Second,
        WriteTimeout: 10 * time.Second,
    }

    log.Println("Starting server on :8080")
    log.Fatal(server.ListenAndServe())
}
```

### Middleware

```go
func loggingMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        start := time.Now()
        next.ServeHTTP(w, r)
        log.Printf("%s %s %s", r.Method, r.URL.Path, time.Since(start))
    })
}

func authMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        if r.Header.Get("Authorization") == "" {
            http.Error(w, "unauthorized", http.StatusUnauthorized)
            return
        }
        next.ServeHTTP(w, r)
    })
}

// Chain middlewares
handler := loggingMiddleware(authMiddleware(mux))
```

## TCP sockets

```go
import "net"

// TCP dial
conn, err := net.DialTimeout("tcp", "example.com:80", 5*time.Second)
if err != nil {
    log.Fatal(err)
}
defer conn.Close()

fmt.Fprintf(conn, "GET / HTTP/1.0\r\n\r\n")
io.Copy(os.Stdout, conn)

// TCP listener
listener, err := net.Listen("tcp", ":9000")
if err != nil {
    log.Fatal(err)
}
defer listener.Close()

for {
    conn, err := listener.Accept()
    if err != nil {
        log.Println(err)
        continue
    }
    go handleConnection(conn)
}
```

## DNS

```go
import "net"

ips, err := net.LookupHost("example.com")
fmt.Println(ips)  // ["93.184.216.34"]

cname, _ := net.LookupCNAME("www.example.com")
addrs, _ := net.LookupAddr("93.184.216.34")  // reverse

// Resolve with specific network
resolver := &net.Resolver{
    PreferGo: true,
}
ips, _ = resolver.LookupHost(context.Background(), "example.com")
```

## Port check

```go
func portOpen(host string, port int, timeout time.Duration) bool {
    addr := net.JoinHostPort(host, strconv.Itoa(port))
    conn, err := net.DialTimeout("tcp", addr, timeout)
    if err != nil {
        return false
    }
    conn.Close()
    return true
}
```

## HTTP client with retry

```go
func httpGetWithRetry(url string, retries int) (*http.Response, error) {
    client := &http.Client{Timeout: 10 * time.Second}

    for i := 0; i < retries; i++ {
        resp, err := client.Get(url)
        if err == nil && resp.StatusCode < 500 {
            return resp, nil
        }
        if resp != nil {
            resp.Body.Close()
        }
        time.Sleep(time.Duration(1<<i) * time.Second)  // exponential backoff
    }
    return nil, fmt.Errorf("request failed after %d retries", retries)
}
```
