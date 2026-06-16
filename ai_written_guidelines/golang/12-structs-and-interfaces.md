# Structs & Interfaces

## Structs

```go
type Service struct {
    Name    string
    Host    string
    Port    int
    Running bool
}

s := Service{
    Name: "web",
    Host: "localhost",
    Port: 8080,
}
s.Running = true
```

### Struct methods

```go
func (s *Service) Start() error {
    s.Running = true
    fmt.Printf("%s started on %s:%d\n", s.Name, s.Host, s.Port)
    return nil
}

func (s *Service) Stop() {
    s.Running = false
}

func (s Service) String() string {
    return fmt.Sprintf("%s (%s:%d)", s.Name, s.Host, s.Port)
}
```

### Struct tags

```go
type Config struct {
    Host    string `yaml:"host" json:"host" env:"HOST"`
    Port    int    `yaml:"port" json:"port" env:"PORT" default:"8080"`
    Debug   bool   `yaml:"debug" json:"debug" env:"DEBUG"`
}

// Read tags with reflect
t := reflect.TypeOf(Config{})
field, _ := t.FieldByName("Host")
tag := field.Tag.Get("yaml")  // "host"
```

## Interfaces

```go
type Runner interface {
    Run(command string) (string, error)
}

type LocalRunner struct{}
func (r LocalRunner) Run(cmd string) (string, error) {
    out, err := exec.Command("sh", "-c", cmd).Output()
    return string(out), err
}

type SSHRunner struct {
    Host string
    User string
}
func (r SSHRunner) Run(cmd string) (string, error) {
    // ssh user@host cmd
    return "", nil
}

// Any Runner works
func execute(r Runner, cmd string) {
    output, err := r.Run(cmd)
    if err != nil {
        log.Fatal(err)
    }
    fmt.Println(output)
}
```

### Interface satisfaction (implicit)

```go
type Stringer interface {
    String() string
}

// *Config automatically satisfies Stringer
func (c *Config) String() string {
    return fmt.Sprintf("%+v", *c)
}

func print(s Stringer) {
    fmt.Println(s.String())
}
```

### Empty interface

```go
func printAny(v interface{}) {
    fmt.Printf("%v\n", v)
}

// Go 1.18+: use any
func printAny(v any) {
    fmt.Printf("%v\n", v)
}
```

### Type assertions

```go
var val any = "hello"

s, ok := val.(string)
if ok {
    fmt.Println(s)
}

// Type switch
switch v := val.(type) {
case string:
    fmt.Println("string:", v)
case int:
    fmt.Println("int:", v)
default:
    fmt.Printf("unknown: %T\n", v)
}
```

## Type embedding

```go
type Logger struct{}
func (l Logger) Log(msg string) {
    fmt.Println(msg)
}

type Service struct {
    Logger           // embedded (no field name)
    Name    string
}

s := Service{Name: "web"}
s.Log("starting")  // method promoted from Logger
s.Logger.Log("explicit call")
```

## Generics (Go 1.18+)

```go
func Min[T constraints.Ordered](a, b T) T {
    if a < b { return a }
    return b
}

Min(1, 2)       // int
Min(1.5, 2.5)   // float64

// Generic struct
type Stack[T any] struct {
    items []T
}

func (s *Stack[T]) Push(item T) {
    s.items = append(s.items, item)
}

func (s *Stack[T]) Pop() (T, bool) {
    if len(s.items) == 0 {
        var zero T
        return zero, false
    }
    item := s.items[len(s.items)-1]
    s.items = s.items[:len(s.items)-1]
    return item, true
}
```

## Common patterns

### Options / functional options

```go
type Server struct {
    host    string
    port    int
    timeout time.Duration
}

type Option func(*Server)

func WithHost(host string) Option {
    return func(s *Server) { s.host = host }
}
func WithPort(port int) Option {
    return func(s *Server) { s.port = port }
}

func NewServer(opts ...Option) *Server {
    s := &Server{
        host:    "localhost",
        port:    8080,
        timeout: 30 * time.Second,
    }
    for _, opt := range opts {
        opt(s)
    }
    return s
}

srv := NewServer(WithHost("0.0.0.0"), WithPort(9090))
```
