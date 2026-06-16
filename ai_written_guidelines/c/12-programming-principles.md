# Programming Principles

## Modular design

Break code into separate translation units with clear interfaces.

```c
// include/config.h
#pragma once

typedef struct {
    char host[256];
    int port;
    int timeout;
} Config;

int config_load(Config *cfg, const char *path);

// src/config.c
#include "config.h"
#include <stdio.h>

int config_load(Config *cfg, const char *path) {
    FILE *fp = fopen(path, "r");
    if (!fp) return -1;
    // parse...
    fclose(fp);
    return 0;
}
```

## DRY (Don't Repeat Yourself)

```c
// Bad: duplicated
void start_web(void) {
    system("systemctl start web");
    log("web started");
}
void stop_web(void) {
    system("systemctl stop web");
    log("web stopped");
}

// Good: single function
void service_ctl(const char *name, const char *action) {
    char cmd[256];
    snprintf(cmd, sizeof(cmd), "systemctl %s %s", action, name);
    system(cmd);
    log("%s %sd", name, action);
}
```

## KISS (Keep It Simple, Stupid)

- Prefer stack allocation over heap when possible
- Prefer simple arrays over complex data structures
- Avoid deep nesting (early returns)
- One function, one responsibility

## Fail Fast

```c
int deploy(const char *env, const char *version) {
    if (!env || !version) return -EINVAL;
    if (strlen(version) > 32) return -EINVAL;
    // proceed...
}
```

## Idempotency

```c
// Safe to call multiple times
int ensure_directory(const char *path) {
    struct stat st;
    if (stat(path, &st) == 0 && S_ISDIR(st.st_mode))
        return 0;  // already exists
    return mkdir(path, 0755);
}
```

## Separation of Concerns

```
Layer         Responsibility
─────         ──────────────
CLI (main)    Parse args, dispatch
Config        Load/validate config
Core          Business logic (no I/O)
I/O           Files, network, system calls
```

## Principle of Least Astonishment

- Follow POSIX conventions
- Use standard function signatures
- Consistent naming: `snake_case` for functions, `SCREAMING_CASE` for macros
- Return meaningful error codes

## C-specific principles

| Principle | Practice |
|-----------|----------|
| Always check return values | `if (fopen(...) == NULL)` |
| Always initialize variables | `int x = 0; char buf[256] = {0};` |
| Use const when possible | `const char *msg` |
| Use static for file-local | `static int internal_helper(...)` |
| Define before use | Forward declarations |
| Handle all errors | No silent failures |
| Free what you malloc | Match every allocation with free |
