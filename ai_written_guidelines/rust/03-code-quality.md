# Code Quality

## Clippy (linting)

```bash
cargo clippy                           # run all lints
cargo clippy -- -D warnings            # warnings as errors
cargo clippy --fix                     # auto-fix
cargo clippy --all-features            # with all features
```

### clippy.toml

```toml
# .clippy.toml
cognitive-complexity-threshold = 15
too-many-arguments-threshold = 5
```

## rustfmt (formatting)

```bash
cargo fmt                              # format in-place
cargo fmt --check                      # check only
cargo fmt -- --config max_width=100    # with config
```

### rustfmt.toml

```toml
# rustfmt.toml
max_width = 100
tab_spaces = 4
edition = "2021"
use_small_heuristics = "Default"
```

## cargo check (fast compilation check)

```bash
cargo check
cargo check --all-features
```

## cargo deny (dependency audit)

```bash
cargo install cargo-deny
cargo deny init
cargo deny check
```

### deny.toml

```toml
[advisories]
db-path = "~/.cargo/advisory-db"
db-urls = ["https://github.com/rustsec/advisory-db"]

[bans]
multiple-versions = "deny"
wildcards = "deny"

[licenses]
unlicensed = "deny"
allow = ["MIT", "Apache-2.0"]
```

## cargo outdated

```bash
cargo install cargo-outdated
cargo outdated
```

## cargo audit (security)

```bash
cargo install cargo-audit
cargo audit
```

## Common issues caught by Clippy

| Issue | Clippy lint |
|-------|-------------|
| Unnecessary `clone()` | `redundant_clone` |
| Too many arguments | `too_many_arguments` |
| Large enum variant | `large_enum_variant` |
| Unnecessary `unwrap()` | `unwrap_used` |
| `if let` instead of `match` | `single_match` |
| Unnecessary `return` | `needless_return` |
| Complex types | `type_complexity` |
| Cognitive complexity | `cognitive_complexity` |
| Manual `is_some()` check | `if_some_then_none` |

## Makefile quality targets

```makefile
.PHONY: lint fmt check audit

lint:
	cargo clippy --all-features -- -D warnings

fmt:
	cargo fmt

fmt-check:
	cargo fmt --check

check:
	cargo check --all-features

audit:
	cargo audit
	cargo deny check

quality: fmt-check lint check test audit
```

## Pre-commit hook

```bash
#!/bin/sh
# .git/hooks/pre-commit
set -euo pipefail

cargo fmt --check
cargo clippy --all-features -- -D warnings
cargo check --all-features
cargo test
```

## Code review checklist

- [ ] `cargo fmt` run
- [ ] `cargo clippy` clean
- [ ] `cargo test` passes
- [ ] All public items have doc comments
- [ ] No `.unwrap()` in library code (use `?` or proper errors)
- [ ] No `unsafe` blocks (or documented why)
- [ ] Errors are properly typed (not just `String`)
- [ ] Dead code is removed
- [ ] Functions are short (< 30 lines)
- [ ] No wildcard imports (`use module::*`)
- [ ] `cargo deny` / `cargo audit` passes
