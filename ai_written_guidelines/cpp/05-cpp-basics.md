# C++ Basics (Modern C++)

## Structure

```cpp
#include <iostream>
#include <string>
#include <vector>

int main(int argc, char *argv[]) {
    std::cout << "Hello from C++" << std::endl;
    return 0;
}
```

## Types

```cpp
int i = 42;
double d = 3.14;
bool b = true;
char c = 'A';
std::string s = "hello";
auto x = 42;           // deduced as int
auto y = 3.14f;        // deduced as float

// Fixed-width (from <cstdint>)
int32_t i32;
uint64_t u64;
size_t sz;
```

## Control flow

```cpp
if (x > 0) {
    // ...
} else if (x == 0) {
    // ...
} else {
    // ...
}

switch (code) {
    case 200: std::cout << "OK\n"; break;
    case 404: std::cout << "Not Found\n"; break;
    default:  std::cout << "Unknown\n";
}

for (int i = 0; i < 10; i++) { }
for (const auto& item : items) { }
while (cond) { }
do { } while (cond);
```

## Functions

```cpp
int add(int a, int b) { return a + b; }

// Default arguments
void connect(std::string host, int port = 8080) { }

// Overloading
void log(std::string msg);
void log(int code, std::string msg);

// auto return type
auto max(auto a, auto b) { return a > b ? a : b; }

// Lambda
auto square = [](int x) { return x * x; };
auto add = [](int a, int b) -> int { return a + b; };

// Lambda with capture
int factor = 2;
auto times = [factor](int x) { return x * factor; };
auto increment = [&]() { counter++; };
```

## auto and decltype

```cpp
auto a = 42;                    // int
auto b = 3.14;                  // double
auto c = std::make_unique<int>(); // std::unique_ptr<int>

decltype(a) d = 100;            // int
```

## Range-based for loop

```cpp
std::vector<int> nums = {1, 2, 3, 4, 5};

for (int n : nums) { }
for (auto& n : nums) { n *= 2; }
for (const auto& n : nums) { std::cout << n; }
```

## Structured bindings (C++17)

```cpp
std::map<std::string, int> config;
for (const auto& [key, value] : config) {
    std::cout << key << "=" << value << "\n";
}

auto [ip, port, ok] = parse_endpoint("127.0.0.1:8080");
```

## nullptr and constexpr

```cpp
int* ptr = nullptr;

constexpr int MAX_BUF = 1024;
constexpr int square(int x) { return x * x; }
static_assert(square(5) == 25);
```

## Namespaces

```cpp
namespace myapp {
    namespace fs = std::filesystem;

    int version() { return 1; }

    namespace detail {
        void internal_helper() { }
    }
}

using namespace myapp;
using myapp::version;
```

## Common stdlib headers for automation

| Header | Purpose |
|--------|---------|
| `<iostream>` | Console I/O |
| `<fstream>` | File I/O |
| `<string>` | `std::string` |
| `<vector>`, `<map>`, `<set>` | Containers |
| `<algorithm>` | Sort, find, transform |
| `<optional>` | `std::optional` (C++17) |
| `<variant>` | `std::variant` (C++17) |
| `<filesystem>` | Path, directory (C++17) |
| `<thread>`, `<mutex>` | Concurrency |
| `<chrono>` | Time and durations |
| `<regex>` | Regular expressions |
| `<random>` | Random number generation |
