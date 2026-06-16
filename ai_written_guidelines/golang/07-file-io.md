# File I/O

## Reading files

```go
import "os"
import "io"
import "bufio"

// Entire file
data, err := os.ReadFile("config.yaml")
if err != nil {
    log.Fatal(err)
}
fmt.Println(string(data))

// Line by line
f, err := os.Open("log.txt")
if err != nil {
    log.Fatal(err)
}
defer f.Close()

scanner := bufio.NewScanner(f)
for scanner.Scan() {
    line := scanner.Text()
    fmt.Println(line)
}
if err := scanner.Err(); err != nil {
    log.Fatal(err)
}

// io.ReadAll (from any reader)
r, _ := os.Open("file.bin")
data, _ := io.ReadAll(r)
```

## Writing files

```go
// Entire file
err := os.WriteFile("output.txt", []byte("hello\n"), 0644)

// Buffered writer
f, err := os.Create("output.txt")
if err != nil {
    log.Fatal(err)
}
defer f.Close()

w := bufio.NewWriter(f)
w.WriteString("line 1\n")
w.WriteString("line 2\n")
w.Flush()  // important: flush buffer to disk

// Append
f, err := os.OpenFile("log.txt", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
if err != nil {
    log.Fatal(err)
}
defer f.Close()
f.WriteString("new entry\n")
```

## File operations

```go
os.Stat("file.txt")                    // file info
os.IsNotExist(err)                     // check if file missing
os.Rename("old.txt", "new.txt")
os.Remove("file.txt")
os.RemoveAll("dir/")                   // recursive delete
os.Mkdir("dir", 0755)
os.MkdirAll("a/b/c", 0755)            // recursive mkdir
os.CreateTemp("", "myapp-*.yaml")      // temp file
os.MkdirTemp("", "myapp-*")            // temp dir
```

## Directory listing

```go
entries, err := os.ReadDir(".")
for _, entry := range entries {
    fmt.Println(entry.Name(), entry.IsDir())
}

// Recursive (with filepath.Walk)
import "path/filepath"

filepath.WalkDir(".", func(path string, d fs.DirEntry, err error) error {
    if err != nil {
        return err
    }
    fmt.Println(path)
    return nil
})
```

## File information

```go
info, err := os.Stat("file.txt")
if err != nil {
    log.Fatal(err)
}

fmt.Println(info.Name())
fmt.Println(info.Size())
fmt.Println(info.IsDir())
fmt.Println(info.Mode())
fmt.Println(info.ModTime())
```

## Embedded files (Go 1.16+)

```go
import "embed"

//go:embed templates/*
var templates embed.FS

//go:embed config.yaml
var configYAML []byte

//go:embed static/index.html
var indexHTML string

func main() {
    data, _ := templates.ReadFile("templates/nginx.conf.j2")
    os.Stdout.Write(data)
}
```

## Common patterns

```go
// Check if file exists
func fileExists(path string) bool {
    _, err := os.Stat(path)
    return !os.IsNotExist(err)
}

// Atomic write (write to temp, rename)
import "crypto/rand"

func atomicWrite(path string, data []byte) error {
    tmp := path + ".tmp"
    if err := os.WriteFile(tmp, data, 0644); err != nil {
        return err
    }
    return os.Rename(tmp, path)
}

// Copy file
func copyFile(src, dst string) error {
    data, err := os.ReadFile(src)
    if err != nil {
        return err
    }
    return os.WriteFile(dst, data, 0644)
}
```
