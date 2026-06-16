# Code Quality

## gofmt (formatting)

```bash
gofmt -l .                          # list unformatted files
gofmt -w .                          # format in-place
gofmt -d .                          # show diff

# gofmt is not configurable by design
# Always run gofmt before committing
```

## go vet (static analysis)

```bash
go vet ./...
go vet -vettool=$(which shadow) ./...   # detect variable shadowing
```

## golangci-lint (comprehensive)

```bash
# Install
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# Run
golangci-lint run ./...
golangci-lint run --fix ./...       # auto-fix
golangci-lint run --fast ./...      # skip slow linters
```

### .golangci.yml

```yaml
linters:
  enable:
    - errcheck
    - gosimple
    - govet
    - ineffassign
    - staticcheck
    - typecheck
    - unused
    - bodyclose
    - godot
    - gofmt
    - goimports
    - misspell
    - revive
    - whitespace

linters-settings:
  errcheck:
    check-type-assertions: true
    check-blank: true
  revive:
    rules:
      - name: exported
        severity: warning

issues:
  exclude-rules:
    - path: _test\.go
      linters:
        - errcheck
```

## staticcheck

```bash
go install honnef.co/go/tools/cmd/staticcheck@latest
staticcheck ./...
```

## Makefile quality targets

```makefile
.PHONY: lint vet fmt tidy

fmt:
	gofmt -w .
	goimports -w .

fmt-check:
	test -z $(shell gofmt -l .)

vet:
	go vet ./...

lint:
	golangci-lint run ./...

tidy:
	go mod tidy
	go mod verify

quality: fmt-check vet lint tidy test
```

## Common issues caught by linters

| Issue | Linter |
|-------|--------|
| Unhandled errors | `errcheck` |
| Shadowed variables | `govet` (shadow) |
| Ineffective assignments | `ineffassign` |
| Dead code | `unused` |
| Not closing HTTP body | `bodyclose` |
| Incorrect printf verbs | `govet` |
| Race conditions | `go build -race` |
| Context not cancelled | `contextcheck` |
| Deep nesting | `gocyclo` |
| Magic numbers | `gomnd` |

## Pre-commit hook

```bash
#!/bin/sh
# .git/hooks/pre-commit
set -euo pipefail

gofmt -w .
go vet ./...
golangci-lint run ./...
go test ./...
```

## Code review checklist

- [ ] `gofmt` run
- [ ] `go vet` clean
- [ ] `golangci-lint` clean
- [ ] No unchecked errors
- [ ] All exported symbols documented
- [ ] Table-driven tests for multiple cases
- [ ] Context is respected in long operations
- [ ] No `goroutine` leaks (ensure they terminate)
- [ ] Errors are wrapped with context
- [ ] No `init()` functions unless necessary
- [ ] Idiomatic naming (no `get` prefix, `snake_case` for tests)
