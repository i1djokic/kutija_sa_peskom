# Build Tools

## CMake

```cmake
cmake_minimum_required(VERSION 3.20)
project(myapp VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Build options
option(BUILD_TESTS "Build tests" ON)
option(ENABLE_SANITIZERS "Enable ASan and UBSan" OFF)

# Sources
set(SOURCES
    src/main.cpp
    src/config.cpp
    src/network.cpp
    src/cli.cpp
)

add_executable(myapp ${SOURCES})
target_include_directories(myapp PRIVATE include/)

# Compiler options
target_compile_options(myapp PRIVATE
    $<$<CONFIG:Release>:-O3 -DNDEBUG>
    $<$<CONFIG:Debug>:-g -O0 -DDEBUG>
)

if(ENABLE_SANITIZERS)
    target_compile_options(myapp PRIVATE -fsanitize=address,undefined)
    target_link_options(myapp PRIVATE -fsanitize=address,undefined)
endif()

# Warnings
target_compile_options(myapp PRIVATE
    -Wall -Wextra -Wpedantic -Werror
    -Wshadow -Wconversion -Wnon-virtual-dtor
)

# Dependencies
find_package(fmt CONFIG REQUIRED)
target_link_libraries(myapp PRIVATE fmt::fmt)

# Tests
if(BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()
```

### CMake Presets

```json
// CMakePresets.json
{
    "version": 3,
    "configurePresets": [
        {
            "name": "debug",
            "binaryDir": "${sourceDir}/build/debug",
            "cacheVariables": {
                "CMAKE_BUILD_TYPE": "Debug",
                "ENABLE_SANITIZERS": "ON"
            }
        },
        {
            "name": "release",
            "binaryDir": "${sourceDir}/build/release",
            "cacheVariables": {
                "CMAKE_BUILD_TYPE": "Release"
            }
        }
    ]
}
```

## Package managers

### Conan

```python
# conanfile.py
from conan import ConanFile

class MyApp(ConanFile):
    settings = "os", "compiler", "build_type", "arch"
    generators = "CMakeDeps", "CMakeToolchain", "VirtualBuildEnv"

    def requirements(self):
        self.requires("fmt/10.2.1")
        self.requires("cli11/2.4.2")
        self.requires("nlohmann_json/3.11.3")

    def build_requirements(self):
        self.tool_requires("cmake/3.27.0")
```

```bash
conan install . --build=missing
cmake --preset conan-default
cmake --build --preset conan-release
```

### vcpkg

```bash
git clone https://github.com/Microsoft/vcpkg.git
./vcpkg/bootstrap-vcpkg.sh

vcpkg install fmt cli11 nlohmann-json
cmake -B build -S . -DCMAKE_TOOLCHAIN_FILE=path/to/vcpkg/scripts/buildsystems/vcpkg.cmake
```

## Makefile (simpler projects)

```makefile
CXX ?= g++
CXXFLAGS ?= -std=c++20 -Wall -Wextra -Werror -O2
LDFLAGS ?=
LIBS ?= -lfmt

SRCS = src/main.cpp src/config.cpp src/network.cpp src/cli.cpp
OBJS = $(SRCS:.cpp=.o)

.PHONY: all clean debug release test

all: myapp

myapp: $(OBJS)
	$(CXX) $(LDFLAGS) -o $@ $^ $(LIBS)

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -MMD -MP -c -o $@ $<

-include $(OBJS:.o=.d)

debug: CXXFLAGS += -g -O0 -DDEBUG -fsanitize=address
debug: LDFLAGS += -fsanitize=address
debug: myapp

release: CXXFLAGS += -O3 -DNDEBUG -march=native
release: myapp

clean:
	rm -rf myapp src/*.o src/*.d

test: myapp
	./myapp --test
```

## Project structure

```
myapp/
  CMakeLists.txt
  CMakePresets.json
  conanfile.py          # or vcpkg.json
  include/
    myapp/
      config.h
      network.h
  src/
    main.cpp
    config.cpp
    network.cpp
  tests/
    CMakeLists.txt
    test_config.cpp
  build/                # gitignored
```
