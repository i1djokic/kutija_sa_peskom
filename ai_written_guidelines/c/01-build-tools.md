# Build Tools

## GCC / Clang basics

```bash
# Compile single source
gcc -std=c17 -Wall -Wextra -o program main.c

# Multiple sources
gcc -std=c17 -Wall -Wextra -o program main.c util.c net.c

# With optimization
gcc -O2 -march=native -o program main.c

# Debug symbols
gcc -g -O0 -o program main.c

# Link with library
gcc -o program main.c -lm            # math library
gcc -o program main.c -lpthread      # pthreads
gcc -o program main.c -lcurl         # libcurl
```

## Common GCC/Clang flags

| Flag | Purpose |
|------|---------|
| `-std=c17` | C standard version |
| `-Wall -Wextra` | Enable warnings |
| `-Werror` | Treat warnings as errors |
| `-O0 -O1 -O2 -O3` | Optimization levels |
| `-g` | Debug symbols |
| `-pg` | Profiling support (gprof) |
| `-fsanitize=address` | AddressSanitizer |
| `-fsanitize=undefined` | UBSan |
| `-DDEBUG` | Define preprocessor macro |
| `-I include/` | Add include path |
| `-L lib/` | Add library path |

## Makefile

```makefile
CC ?= gcc
CFLAGS ?= -std=c17 -Wall -Wextra -Werror -O2
LDFLAGS ?=
LIBS ?= -lm

SRCS = main.c util.c config.c net.c
OBJS = $(SRCS:.c=.o)
DEPS = $(OBJS:.o=.d)

.PHONY: all clean debug release test

all: myapp

# Include auto-generated dependencies
-include $(DEPS)

myapp: $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $^ $(LIBS)

%.o: %.c
	$(CC) $(CFLAGS) -MMD -MP -c -o $@ $<

debug: CFLAGS += -g -O0 -DDEBUG -fsanitize=address
debug: LDFLAGS += -fsanitize=address
debug: myapp

release: CFLAGS += -O3 -DNDEBUG
release: myapp

clean:
	rm -rf myapp *.o *.d

test: myapp
	./myapp --test
```

## CMake

```cmake
cmake_minimum_required(VERSION 3.20)
project(myapp C)

set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Sources
add_executable(myapp
    src/main.c
    src/util.c
    src/config.c
    src/net.c
)

# Include directories
target_include_directories(myapp PRIVATE include/)

# Compile options
target_compile_options(myapp PRIVATE
    -Wall -Wextra -Werror
)

# Debug build
set(CMAKE_C_FLAGS_DEBUG "-g -O0 -DDEBUG -fsanitize=address")
set(CMAKE_EXE_LINKER_FLAGS_DEBUG "-fsanitize=address")

# Find package
find_package(CURL REQUIRED)
target_link_libraries(myapp PRIVATE CURL::libcurl m)
```

```bash
# Build with CMake
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
```

## Static library

```bash
ar rcs libutil.a util.o config.o
gcc -o myapp main.c -L. -lutil
```

## Shared library

```bash
gcc -fPIC -c util.c -o util.o
gcc -shared -o libutil.so util.o
gcc -o myapp main.c -L. -lutil
LD_LIBRARY_PATH=. ./myapp
```

## pkg-config

```bash
# Check flags for a library
pkg-config --cflags --libs libcurl
# -I/usr/include -L/usr/lib -lcurl

# Use in Makefile
CFLAGS += $(shell pkg-config --cflags libcurl)
LIBS += $(shell pkg-config --libs libcurl)
```

## Project structure

```
project/
  Makefile          # or CMakeLists.txt
  README.md
  include/
    myapp.h
    config.h
  src/
    main.c
    util.c
    config.c
  tests/
    test_util.c
    test_config.c
  build/            # build output (gitignored)
```
