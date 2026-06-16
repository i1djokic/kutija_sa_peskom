# Programming Principles

## SOLID in C++

| Letter | Principle | C++ Practice |
|--------|-----------|-------------|
| **S** | Single Responsibility | One class = one concern |
| **O** | Open/Closed | Template methods, strategy pattern |
| **L** | Liskov Substitution | Correct inheritance, `virtual` |
| **I** | Interface Segregation | Small abstract classes |
| **D** | Dependency Inversion | Inject via constructor, not hardcoded |

## RAII (Resource Acquisition Is Initialization)

The most important C++ principle.

```cpp
// File automatically closes when `log` goes out of scope
std::ofstream log("app.log");
log << "event\n";
// No manual close needed

// Mutex automatically unlocks
std::lock_guard<std::mutex> lock(mtx);
shared_data++;
// Automatically unlocks at end of scope
```

## DRY (Don't Repeat Yourself)

```cpp
// Bad: duplicated logic
void start_service(const std::string& name);
void stop_service(const std::string& name);

// Good: single function
void service_ctl(const std::string& name, const std::string& action) {
    auto cmd = "systemctl " + action + " " + name;
    std::system(cmd.c_str());
}
```

## KISS (Keep It Simple, Stupid)

- Prefer `std::vector` over custom containers
- Prefer free functions over classes with just one method
- Avoid deep template metaprogramming unless necessary
- One function, one responsibility

## YAGNI (You Ain't Gonna Need It)

```cpp
// Don't add this until you have at least 3 use cases
template<typename... Args>
class SuperFlexibleConfig { ... };
```

## Composition over Inheritance

```cpp
// Inheritance (rigid)
class Service {
    virtual void start() = 0;
};

// Composition (flexible)
class Service {
    std::unique_ptr<Logger> logger_;
    std::unique_ptr<HealthChecker> checker_;
};
```

## Rule of Zero / Five

```cpp
// Rule of Zero: let RAII members handle resource mgmt
class Service {
    std::string name_;
    std::unique_ptr<Logger> logger_;
};

// Rule of Five: when you manage a resource manually
class Resource {
    ~Resource();                          // destructor
    Resource(const Resource&);           // copy ctor
    Resource& operator=(const Resource&); // copy assign
    Resource(Resource&&) noexcept;       // move ctor
    Resource& operator=(Resource&&) noexcept; // move assign
};
```

## Fail Fast

```cpp
void deploy(const std::string& env, const std::string& version) {
    if (env.empty()) throw std::invalid_argument("env required");
    if (version.empty()) throw std::invalid_argument("version required");
    // proceed...
}
```

## const Correctness

```cpp
class Config {
public:
    [[nodiscard]] int port() const { return port_; }
    void set_port(int port) { port_ = port; }

private:
    int port_ = 8080;
};
```

## Idempotency

```cpp
// Safe to call multiple times
void ensure_directory(const std::filesystem::path& path) {
    std::filesystem::create_directories(path);
}

[[nodiscard]] bool ensure_user(const std::string& username) {
    auto cmd = "id " + username + " >/dev/null 2>&1";
    if (std::system(cmd.c_str()) == 0) return false;  // exists
    cmd = "useradd " + username;
    return std::system(cmd.c_str()) == 0;
}
```

## Summary

```
RAII       → Automatic resource management
SOLID      → Maintainable OOP
DRY        → No duplication
KISS       → Simple over clever
YAGNI      → Only what you need
Fail Fast  → Validate early
const      → Immutable by default
Idempotency → Safe to retry
```
