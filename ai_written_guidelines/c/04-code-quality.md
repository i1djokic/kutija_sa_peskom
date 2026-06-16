# Code Quality

## Linting with cppcheck

```bash
cppcheck --enable=all --inconclusive --std=c17 src/
cppcheck --enable=warning,style,performance,portability src/
cppcheck --suppress=missingIncludeSystem --project=compile_commands.json
```

## clang-tidy

```bash
# Generate compile_commands.json
cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON .

# Run clang-tidy
clang-tidy src/*.c -- -Iinclude/

# Fix issues automatically
clang-tidy src/*.c --fix -- -Iinclude/
```

### .clang-tidy

```yaml
---
Checks: >
  clang-analyzer-*,
  bugprone-*,
  performance-*,
  readability-*,
  modernize-*,
  -readability-identifier-length,
  -readability-magic-numbers
WarningsAsErrors: clang-analyzer-*
HeaderFilterRegex: '.*'
```

## Formatting with clang-format

```bash
clang-format -i src/*.c include/*.h   # format in-place
clang-format --dry-run -Werror src/*.c  # check only
```

### .clang-format

```yaml
---
BasedOnStyle: LLVM
IndentWidth: 4
ColumnLimit: 100
AllowShortFunctionsOnASingleLine: None
BreakBeforeBraces: Allman
PointerAlignment: Left
IncludeCategories:
  - Regex: '^<.*>'
    Priority: 1
  - Regex: '^".*"'
    Priority: 2
  - Regex: '.*'
    Priority: 3
```

## Static analysis with splint

```bash
splint +posixlib src/*.c
```

## Security analysis

```bash
flawfinder src/
flawfinder --html src/ > flaws.html
```

## Makefile quality targets

```makefile
.PHONY: lint format tidy analyze

lint:
	cppcheck --enable=all --std=c17 src/

format:
	clang-format -i src/*.c include/*.h

format-check:
	clang-format --dry-run -Werror src/*.c include/*.h

tidy:
	clang-tidy src/*.c -- -Iinclude/

analyze:
	flawfinder src/

quality: lint format-check tidy analyze test
```

## Compiler warnings (treat as errors)

```makefile
CFLAGS += -Wall -Wextra -Wpedantic -Werror
CFLAGS += -Wshadow -Wconversion -Wdouble-promotion
CFLAGS += -Wformat=2 -Wformat-security
CFLAGS += -Wstrict-overflow=5 -Wnull-dereference
CFLAGS += -Wstack-protector -fstack-protector-strong
```

## Code review checklist

- [ ] No memory leaks (all `malloc` has matching `free`)
- [ ] Buffer sizes checked (`snprintf` over `sprintf`, `strncpy` over `strcpy`)
- [ ] Return values checked (fopen, malloc, fread, etc.)
- [ ] No uninitialized variables
- [ ] No integer overflows
- [ ] Pointer arithmetic is safe
- [ ] Thread safety (reentrant functions, locks where needed)
- [ ] No magic numbers (use `#define` or `enum`)
- [ ] Resource cleanup in all code paths (including error paths)
