# Build & Modules

## Go module basics

```bash
go mod init github.com/user/myapp
go mod tidy              # add missing, remove unused
go mod download          # download all dependencies
go mod vendor            # create vendor directory
go mod verify            # verify checksums
```

## go.mod structure

```
module github.com/user/myapp

go 1.22

require (
    github.com/spf13/cobra v1.8.0
    github.com/spf13/viper v1.18.0
    golang.org/x/sync v0.6.0
)
```

## Build commands

```bash
go build ./...                         # build all packages
go build -o myapp .                    # output binary name
go build -ldflags="-s -w" .           # strip debug info
go build -tags=production .           # build tags

go install                             # install to $GOPATH/bin
go clean -cache                        # clean build cache
go clean -modcache                     # clean module cache
```

## Cross-compilation

```bash
GOOS=linux GOARCH=amd64 go build -o myapp-linux-amd64 .
GOOS=darwin GOARCH=arm64 go build -o myapp-darwin-arm64 .
GOOS=windows GOARCH=amd64 go build -o myapp.exe .

# Common combinations
# linux/amd64, linux/arm64, darwin/amd64, darwin/arm64, windows/amd64
```

## Build-time variables

```go
var (
    Version = "dev"
    Commit  = "none"
    Date    = "unknown"
)
```

```bash
go build -ldflags="\
    -X main.Version=1.0.0 \
    -X main.Commit=$(git rev-parse --short HEAD) \
    -X main.Date=$(date -u +%Y-%m-%d)" .
```

## Makefile

```makefile
APP ?= myapp
VERSION ?= $(shell git describe --tags 2>/dev/null || echo "dev")
COMMIT ?= $(shell git rev-parse --short HEAD)
BUILD_DATE ?= $(shell date -u +%Y-%m-%dT%H:%M:%SZ)
LDFLAGS := -ldflags="-s -w -X main.Version=$(VERSION) -X main.Commit=$(COMMIT) -X main.Date=$(BUILD_DATE)"

.PHONY: build build-all test lint clean

build:
	go build $(LDFLAGS) -o bin/$(APP) .

build-all:
	GOOS=linux   GOARCH=amd64 go build $(LDFLAGS) -o bin/$(APP)-linux-amd64 .
	GOOS=darwin  GOARCH=amd64 go build $(LDFLAGS) -o bin/$(APP)-darwin-amd64 .
	GOOS=darwin  GOARCH=arm64 go build $(LDFLAGS) -o bin/$(APP)-darwin-arm64 .
	GOOS=windows GOARCH=amd64 go build $(LDFLAGS) -o bin/$(APP).exe .

test:
	go test -v -race -cover ./...

lint:
	golangci-lint run ./...

clean:
	rm -rf bin/
	go clean -cache
```

## Workspaces (Go 1.18+)

```bash
go work init ./app1 ./app2 ./shared
go work use ./new-module
go work sync
```

```
go.work
app1/
  go.mod
app2/
  go.mod
shared/
  go.mod
```

## Project structure

```
myapp/
  go.mod
  go.sum
  Makefile
  cmd/
    myapp/
      main.go
  internal/
    config/
      config.go
    deploy/
      deploy.go
    health/
      health.go
  pkg/
    api/
      client.go
    utils/
      utils.go
  test/
    testdata/
```

## Common commands reference

| Command | Purpose |
|---------|---------|
| `go build` | Compile |
| `go test` | Run tests |
| `go fmt` | Format code |
| `go vet` | Static analysis |
| `go mod tidy` | Clean dependencies |
| `go run` | Run without installing |
| `go doc` | Show documentation |
| `go generate` | Run code generators |
| `go clean` | Remove build artifacts |
