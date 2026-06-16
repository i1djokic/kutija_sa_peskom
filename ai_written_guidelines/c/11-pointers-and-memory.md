# Pointers & Memory

## Pointers basics

```c
int x = 42;
int *p = &x;    // p points to x
*p = 10;        // x is now 10

// NULL pointer
int *ptr = NULL;
if (ptr == NULL) { /* safe to check */ }
```

## Dynamic memory

```c
#include <stdlib.h>

// Single allocation
int *p = malloc(sizeof(int));
if (!p) { /* handle error */ }
*p = 42;
free(p);

// Array
int *arr = malloc(10 * sizeof(int));
if (!arr) { /* handle error */ }
arr[0] = 1;
free(arr);

// Zero-initialized
int *z = calloc(10, sizeof(int));  // all zero

// Reallocate
arr = realloc(arr, 20 * sizeof(int));
```

## Common pitfalls

```c
// Memory leak
void leak(void) {
    int *p = malloc(100);
    // forget to free(p);
}

// Double free
free(p);
free(p);  // undefined behavior

// Use after free
free(p);
*p = 42;  // undefined behavior

// Buffer overflow
char buf[10];
strcpy(buf, "this string is too long");
```

## Function pointers

```c
#include <stdio.h>

int add(int a, int b) { return a + b; }
int sub(int a, int b) { return a - b; }

int main(void) {
    int (*op)(int, int) = add;
    printf("%d\n", op(5, 3));  // 8

    op = sub;
    printf("%d\n", op(5, 3));  // 2

    return 0;
}
```

## Callbacks

```c
typedef void (*callback_t)(const char *msg);

void notify(callback_t cb, const char *msg) {
    cb(msg);
}

void log_to_file(const char *msg) { /* ... */ }
void log_to_stdout(const char *msg) { puts(msg); }

notify(log_to_stdout, "hello");
```

## Void pointer (generic pointer)

```c
void *ptr;
int x = 10;
ptr = &x;
printf("%d\n", *(int *)ptr);  // must cast back
```

## String duplication

```c
#include <string.h>

char *copy = strdup(original);  // POSIX, allocates with malloc
// ... use it ...
free(copy);
```

## Arena allocator pattern

```c
typedef struct {
    char *memory;
    size_t used;
    size_t capacity;
} Arena;

Arena arena_new(size_t capacity) {
    return (Arena){ .memory = malloc(capacity), .capacity = capacity };
}

void *arena_alloc(Arena *a, size_t size) {
    if (a->used + size > a->capacity) return NULL;
    void *ptr = a->memory + a->used;
    a->used += size;
    return ptr;
}

void arena_free(Arena *a) {
    free(a->memory);
    a->memory = NULL;
}
```
