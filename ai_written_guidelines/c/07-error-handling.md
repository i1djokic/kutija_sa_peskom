# Error Handling

## Return codes

```c
#include <stdlib.h>
#include <stdio.h>

#define EXIT_SUCCESS 0
#define EXIT_FAILURE 1

int main(void) {
    if (do_something() != 0) {
        return EXIT_FAILURE;
    }
    return EXIT_SUCCESS;
}
```

## errno

```c
#include <errno.h>
#include <string.h>
#include <stdio.h>

FILE *fp = fopen("config.yaml", "r");
if (!fp) {
    fprintf(stderr, "Error: %s\n", strerror(errno));
    // errno is set by the failing function
    // Always check immediately after failure
}
```

## Common errno values

```c
#include <errno.h>

EPERM    // Operation not permitted
ENOENT   // No such file or directory
EACCES   // Permission denied
EEXIST   // File exists
EINVAL   // Invalid argument
ENOMEM   // Out of memory
EBUSY    // Resource busy
ETIMEDOUT // Connection timed out
ECONNREFUSED // Connection refused
```

## Error handling patterns

```c
// Pattern 1: return code
int init_server(Server *srv, int port) {
    if (port <= 0 || port > 65535) {
        return -EINVAL;
    }
    // ...
    return 0;
}

// Pattern 2: boolean return with out-param
int read_config(const char *path, Config *out) {
    FILE *fp = fopen(path, "r");
    if (!fp) return -1;
    // parse...
    fclose(fp);
    return 0;
}

// Pattern 3: goto cleanup (common in C)
int do_work(void) {
    int ret = 0;
    FILE *fp = NULL;
    char *buf = NULL;

    fp = fopen("file.txt", "r");
    if (!fp) { ret = -1; goto cleanup; }

    buf = malloc(1024);
    if (!buf) { ret = -1; goto cleanup; }

    // ... main logic ...

cleanup:
    free(buf);
    if (fp) fclose(fp);
    return ret;
}
```

## assert

```c
#include <assert.h>

int divide(int a, int b) {
    assert(b != 0);   // crashes in debug; removed with NDEBUG
    return a / b;
}
```

## setjmp/longjmp (non-local jumps)

```c
#include <setjmp.h>

jmp_buf env;

void handle_error(void) {
    longjmp(env, 1);  // jump back to setjmp
}

int main(void) {
    if (setjmp(env) == 0) {
        // normal execution
        handle_error();
    } else {
        // error recovery
        fprintf(stderr, "Recovered from error\n");
    }
}
```

## Custom error struct pattern

```c
typedef struct {
    int code;
    char message[256];
} Error;

#define OK { .code = 0, .message = "" }
#define ERR(code, msg) { .code = (code), .message = (msg) }

Error do_something(void) {
    if (/* fail */) {
        return ERR(42, "something went wrong");
    }
    return OK;
}

Error err = do_something();
if (err.code != 0) {
    fprintf(stderr, "%s\n", err.message);
}
```
