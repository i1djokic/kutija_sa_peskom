# Debugging & Profiling

## GDB

```bash
# Compile with debug symbols
gcc -g -O0 -o program main.c

# Start GDB
gdb ./program
gdb ./program core        # analyze core dump
gdb ./program 1234        # attach to PID 1234
```

### Common GDB commands

```gdb
run                  # start program
run arg1 arg2        # with arguments
break main           # breakpoint at function
break file.c:42      # breakpoint at line
info break           # list breakpoints
delete 1             # delete breakpoint #1

next                 # step over
step                 # step into
continue             # resume execution
finish               # return from function

print x              # print variable
print &x             # print address
print *ptr           # dereference pointer
display x            # auto-print every step

backtrace            # call stack
frame 2              # switch to frame #2
info locals          # local variables
list                 # show source code

watch x              # watchpoint (break on change)
```

### GDB TUI mode

```bash
gdb -tui ./program
```

## Valgrind

```bash
valgrind --leak-check=full ./program
valgrind --tool=memcheck --leak-check=full --show-leak-kinds=all ./program
valgrind --tool=callgrind ./program   # profiling
```

### Interpreting output

```
==1234== 40 bytes in 1 blocks are definitely lost in loss record 1 of 3
==1234==    at 0x484...: malloc (in /usr/lib/valgrind/...)
==1234==    by 0x1091A3: create_config (config.c:42)
==1234==    by 0x1092B1: main (main.c:15)
```

## AddressSanitizer (ASan)

```c
// Compile with:
// gcc -fsanitize=address -g -O1 -o program main.c
// ./program

// Detects:
//   - buffer overflows
//   - use-after-free
//   - memory leaks (with LSAN)
```

```bash
gcc -fsanitize=address -fsanitize=leak -g -O1 -o program main.c
ASAN_OPTIONS=detect_leaks=1 ./program
```

## UndefinedBehaviorSanitizer (UBSan)

```bash
gcc -fsanitize=undefined -g -O1 -o program main.c
```

## Profiling with perf (Linux)

```bash
perf record ./program
perf report
perf stat ./program              # basic counters
perf top                         # live profiling
```

## Profiling with gprof

```bash
gcc -pg -O2 -o program main.c
./program                        # produces gmon.out
gprof ./program gmon.out > profile.txt
```

## Static analysis

```bash
# cppcheck
cppcheck --enable=all --inconclusive --std=c17 src/

# clang-tidy
clang-tidy src/*.c -- -Iinclude/

# flawfinder (security analysis)
flawfinder src/
```

## Common memory errors

| Error | Symptom | Tool |
|-------|---------|------|
| Buffer overflow | Crash, corruption | ASan, Valgrind |
| Use-after-free | Crash, corruption | ASan, Valgrind |
| Double free | Crash | ASan, Valgrind |
| Memory leak | Growing memory | Valgrind, LSAN |
| Uninitialized read | Random values | Valgrind, MSan |
| Stack overflow | Segfault | GDB backtrace |
| Null dereference | Segfault | GDB, ASan |

## Core dump debugging

```bash
ulimit -c unlimited          # enable core dumps
./program                    # crash
gdb ./program core
(gdb) bt                     # backtrace at crash
(gdb) info locals            # variable values
```
