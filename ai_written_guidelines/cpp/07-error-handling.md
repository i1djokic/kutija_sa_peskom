# Error Handling

## Exceptions

```cpp
#include <stdexcept>
#include <iostream>

void connect(const std::string& host, int port) {
    if (port <= 0 || port > 65535) {
        throw std::invalid_argument("invalid port: " + std::to_string(port));
    }
    if (host.empty()) {
        throw std::runtime_error("host cannot be empty");
    }
}

try {
    connect("example.com", 8080);
} catch (const std::invalid_argument& e) {
    std::cerr << "Config error: " << e.what() << "\n";
} catch (const std::runtime_error& e) {
    std::cerr << "Runtime error: " << e.what() << "\n";
} catch (const std::exception& e) {
    std::cerr << "Unknown error: " << e.what() << "\n";
}
```

## Custom exceptions

```cpp
class AutomationError : public std::runtime_error {
    using std::runtime_error::runtime_error;
};

class ConfigError : public AutomationError {
public:
    explicit ConfigError(const std::string& msg)
        : AutomationError("config: " + msg) {}
};

class ExecutionError : public AutomationError {
public:
    ExecutionError(const std::string& cmd, int exit_code)
        : AutomationError("'" + cmd + "' failed with code " + std::to_string(exit_code))
        , exit_code_(exit_code) {}

    int exit_code() const { return exit_code_; }
private:
    int exit_code_;
};
```

## noexcept

```cpp
// Guarantees no exception will be thrown
int get_value() const noexcept { return value_; }

// Conditional noexcept
void swap(T& other) noexcept(std::is_nothrow_swappable_v<T>);
```

## std::optional for expected failures

```cpp
#include <optional>

std::optional<int> parse_port(const std::string& s) {
    char* end;
    long port = std::strtol(s.c_str(), &end, 10);
    if (*end != '\0' || port < 1 || port > 65535) {
        return std::nullopt;
    }
    return static_cast<int>(port);
}

if (auto port = parse_port("8080")) {
    std::cout << *port << "\n";
}
```

## std::expected (C++23)

```cpp
#include <expected>

enum class ParseError { InvalidPort, OutOfRange };

std::expected<int, ParseError> parse_port(const std::string& s) {
    int port = std::stoi(s);
    if (port < 1) return std::unexpected(ParseError::OutOfRange);
    if (port > 65535) return std::unexpected(ParseError::OutOfRange);
    return port;
}

auto result = parse_port("8080");
if (result) {
    use_port(*result);
} else {
    handle_error(result.error());
}
```

## RAII for cleanup

```cpp
class ScopedCleanup {
    std::function<void()> cleanup_;
public:
    explicit ScopedCleanup(std::function<void()> cleanup)
        : cleanup_(std::move(cleanup)) {}
    ~ScopedCleanup() { if (cleanup_) cleanup_(); }
};

void process() {
    ScopedCleanup cleanup([]{ std::cout << "cleaning up\n"; });
    if (/* fail */) throw std::runtime_error("error");
    // cleanup runs on both normal exit and exception
}
```

## Best practices

- Throw by value, catch by reference
- Use `std::exception` hierarchy (or custom derived)
- Mark destructors `noexcept` (they are by default)
- Use `noexcept` for moves and swaps
- Don't throw in destructors
- Use `std::optional` for "maybe no value" (not exceptions)
- Use `std::expected` for recoverable errors (C++23)
- RAII guarantees cleanup even with exceptions
