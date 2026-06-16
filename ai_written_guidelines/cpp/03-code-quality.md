# Code Quality

## clang-tidy

```bash
# Generate compile_commands.json
cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON .

# Run
clang-tidy src/*.cpp -- -Iinclude/
clang-tidy src/*.cpp --fix -- -Iinclude/
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
  cppcoreguidelines-*,
  -cppcoreguidelines-avoid-magic-numbers,
  -readability-magic-numbers,
  -readability-identifier-length
WarningsAsErrors: clang-analyzer-*
HeaderFilterRegex: '.*'
CheckOptions:
  - key: modernize-use-trailing-return-type.IgnoreMacros
    value: 'false'
```

## clang-format

```bash
clang-format -i src/*.cpp include/*.hpp
clang-format --dry-run -Werror src/*.cpp
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
AccessModifierOffset: -4
NamespaceIndentation: All
Standard: c++20
```

## cppcheck

```bash
cppcheck --enable=all --std=c++20 --suppress=missingIncludeSystem src/
cppcheck --enable=warning,style,performance,portability src/
```

## Include What You Use (IWYU)

```bash
iwyu_tool.py -p build/ src/*.cpp
fix_includes.py --noblanks < iwyu_output
```

## CMake quality targets

```cmake
add_custom_target(lint
    COMMAND cppcheck --enable=all --std=c++20 src/
    COMMENT "Running cppcheck"
)

add_custom_target(format
    COMMAND clang-format -i src/*.cpp include/*.hpp
    COMMENT "Formatting sources"
)

add_custom_target(tidy
    COMMAND clang-tidy src/*.cpp -- -Iinclude/
    COMMENT "Running clang-tidy"
)
```

## Compiler warnings

```cmake
target_compile_options(myapp PRIVATE
    -Wall -Wextra -Wpedantic -Werror
    -Wshadow
    -Wconversion
    -Wsign-conversion
    -Wnon-virtual-dtor
    -Wold-style-cast
    -Wcast-align
    -Wunused
    -Woverloaded-virtual
    -Wnull-dereference
    -Wformat=2
)
```

## Modern C++ guidelines

| Guideline | Rationale |
|-----------|-----------|
| Prefer `std::array` / `std::vector` over raw arrays | Safety, bounds checking |
| Use `auto` for complex types | Readability, consistency |
| Prefer `unique_ptr` over raw owning pointers | No manual delete |
| Use `const` whenever possible | Correctness, readability |
| Prefer `nullptr` over `NULL` | Type safety |
| Use `override` on overridden methods | Catch signature mismatches |
| Prefer scoped enums (`enum class`) | Type safety, no pollution |
| Use `[[nodiscard]]` for error-prone returns | No ignored errors |
| Prefer `std::optional` over sentinel values | Explicit "no value" |
| RAII for all resources | Exception safety |
| Avoid raw `new` / `delete` | RAII handles it |
| Use `<filesystem>` over platform APIs | Portability |
