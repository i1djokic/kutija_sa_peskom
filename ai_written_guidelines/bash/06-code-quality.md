# Code Quality

## shellcheck — Static Analysis

```bash
# Install
apt install -y shellcheck    # Debian/Ubuntu
brew install shellcheck      # macOS

# Run
shellcheck script.sh
shellcheck -x script.sh      # follow source directives
shellcheck -s bash script.sh # specify shell dialect

# Common warnings and fixes

# SC2086: Double quote to prevent globbing/word splitting
# Bad:
rm -rf $dir/*
# Good:
rm -rf "$dir"/*

# SC2002: Useless cat
# Bad:
cat file | grep pattern
# Good:
grep pattern file

# SC2034: Variable appears unused
# Declare with _ prefix for intentional unused:
_ignore_me=1

# SC1090: Can't follow sourced file
# Use -x flag or make the path explicit:
source "$(dirname "$0")/lib/common.sh"

# SC2155: Declare and assign separately
# Bad:
local var=$(cmd)
# Good:
local var
var=$(cmd)

# SC2206: Quote to prevent word splitting
# Bad:
arr=($(cmd))
# Good:
readarray -t arr < <(cmd)
```

## shfmt — Code Formatter

```bash
# Install
apt install -y shfmt        # Debian/Ubuntu
brew install shfmt           # macOS

# Format in-place
shfmt -w script.sh

# Check (diff only)
shfmt -d script.sh

# Common options
shfmt -i 4 script.sh         # 4-space indent (default is tab)
shfmt -ci script.sh          # switch cases indented
shfmt -bn script.sh          # braces on new line (K&R style)
shfmt -sr script.sh          # redirect operators followed by space

# Recursive format
shfmt -w -l .                # list + write all shell files
```

## Project Structure

```
project/
├── bin/              # Executable scripts (entry points)
├── lib/              # Sourced libraries
│   ├── common.sh
│   ├── deploy.sh
│   └── monitor.sh
├── conf/             # Config files
│   ├── config.sh
│   └── default.env
├── tests/            # Tests
│   └── test_deploy.sh
└── Makefile          # Automation
```

## CI Integration

```yaml
# .github/workflows/lint.yml
name: Shell Lint
on: [push]
jobs:
  shellcheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: sudo apt install -y shellcheck shfmt
      - run: shellcheck bin/*.sh lib/*.sh
      - run: shfmt -d bin/*.sh lib/*.sh
```

## Testing Bash Scripts

```bash
# Using bats (Bash Automated Testing System)
# Install: apt install -y bats

# tests/test_deploy.sh
setup() {
    load '../lib/common.sh'
}

@test "log outputs formatted message" {
    result=$(log "INFO" "test")
    [[ "$result" == *"[INFO] test"* ]]
}

@test "die exits with error" {
    run die "fatal error"
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"fatal error"* ]]
}
```

## Makefile for Script Projects

```makefile
# Makefile
SHELL := /bin/bash
SCRIPTS := $(wildcard bin/*.sh lib/*.sh)

.PHONY: lint format test

lint:
	shellcheck $(SCRIPTS)

format:
	shfmt -w $(SCRIPTS)

format-check:
	shfmt -d $(SCRIPTS)

test:
	bats tests/

all: lint format-check test
```
