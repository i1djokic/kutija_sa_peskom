# C Basics

## Structure of a C program

```c
#include <stdio.h>
#include <stdlib.h>

#define MAX_BUF 1024

int main(int argc, char *argv[]) {
    printf("Hello from C\n");
    return EXIT_SUCCESS;
}
```

## Basic types

```c
char        // 1 byte
short       // 2 bytes
int         // 4 bytes
long        // 8 bytes (LP64)
long long   // 8 bytes
float       // 4 bytes
double      // 8 bytes
_Bool       // 0 or 1 (bool with <stdbool.h>)

// Exact-width types (from <stdint.h>)
int8_t, uint8_t
int16_t, uint16_t
int32_t, uint32_t
int64_t, uint64_t
size_t      // unsigned result of sizeof
ssize_t     // signed size_t
```

## Control flow

```c
// if / else
if (x > 0) {
    puts("positive");
} else if (x == 0) {
    puts("zero");
} else {
    puts("negative");
}

// switch
switch (code) {
    case 200: puts("OK"); break;
    case 404: puts("Not Found"); break;
    default:  puts("Unknown");
}

// loops
for (int i = 0; i < 10; i++) { }
while (cond) { }
do { } while (cond);
```

## Functions

```c
int add(int a, int b) {
    return a + b;
}

// Forward declaration
void helper(void);

// Static (file-local) function
static int internal_only(void) {
    return 42;
}

// Inline
static inline int max(int a, int b) {
    return a > b ? a : b;
}
```

## Preprocessor

```c
#define VERSION "1.0.0"
#define MAX(a, b) ((a) > (b) ? (a) : (b))

// Conditional compilation
#ifdef DEBUG
    #define LOG(fmt, ...) fprintf(stderr, fmt, __VA_ARGS__)
#else
    #define LOG(fmt, ...) ((void)0)
#endif

// Include guard
#ifndef MY_HEADER_H
#define MY_HEADER_H
// ...
#endif

// Better: #pragma once (most compilers)
#pragma once
```

## Arrays & strings

```c
int arr[10];
int arr[] = {1, 2, 3};
arr[0] = 10;

// Strings (null-terminated char arrays)
char s1[] = "hello";
char *s2 = "world";         // string literal (read-only)
char buf[64];
snprintf(buf, sizeof(buf), "%s %s", s1, s2);

// String functions (<string.h>)
strlen(s);      // length
strcmp(a, b);   // compare (0 = equal)
strcpy(dst, src);
strncpy(dst, src, n);
strcat(dst, src);
strstr(haystack, needle);
strtok(str, delim);
```

## Structs

```c
struct Config {
    char host[256];
    int port;
    int timeout;
};

// Typedef
typedef struct {
    char name[64];
    int pid;
    int status;
} Process;

// Usage
struct Config cfg = { .host = "localhost", .port = 8080 };
Process p = { .name = "nginx", .pid = 1234, .status = 1 };
```

## Enums

```c
typedef enum {
    STATUS_OK,
    STATUS_WARNING,
    STATUS_ERROR,
    STATUS_CRITICAL,
} Status;

Status s = STATUS_OK;
```

## Common pattern: config structure

```c
typedef struct {
    char host[256];
    int port;
    int timeout;
    int verbose;
} AppConfig;

int parse_config(AppConfig *cfg, int argc, char *argv[]) {
    // Defaults
    snprintf(cfg->host, sizeof(cfg->host), "localhost");
    cfg->port = 8080;
    cfg->timeout = 30;
    cfg->verbose = 0;
    return 0;
}
```

## Error handling pattern

```c
#include <errno.h>
#include <string.h>

FILE *fp = fopen("config.yaml", "r");
if (!fp) {
    fprintf(stderr, "Error opening file: %s\n", strerror(errno));
    return EXIT_FAILURE;
}
```
