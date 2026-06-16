# STL Containers & Algorithms

## Containers overview

| Container | Header | Use case |
|-----------|--------|----------|
| `std::vector` | `<vector>` | Dynamic array (default choice) |
| `std::array` | `<array>` | Fixed-size array (stack) |
| `std::string` | `<string>` | Dynamic text |
| `std::map` | `<map>` | Ordered key-value |
| `std::unordered_map` | `<unordered_map>` | Hash map (O(1) lookup) |
| `std::set` | `<set>` | Ordered unique elements |
| `std::unordered_set` | `<unordered_set>` | Hash set |
| `std::deque` | `<deque>` | Double-ended queue |
| `std::list` | `<list>` | Doubly linked list (rarely needed) |
| `std::optional` | `<optional>` | Maybe-value (C++17) |
| `std::variant` | `<variant>` | Type-safe union (C++17) |

## std::vector

```cpp
#include <vector>

std::vector<int> v = {1, 2, 3};
v.push_back(4);
v.emplace_back(5);     // in-place construction
v.pop_back();

v.size();    // number of elements
v.empty();   // bool
v[0];        // unchecked access
v.at(0);     // checked access (throws on OOB)
v.front();   // first element
v.back();    // last element
v.data();    // raw pointer to underlying array

// Reserve capacity
v.reserve(100);
v.shrink_to_fit();

// Iterate
for (size_t i = 0; i < v.size(); i++) { }
for (auto& x : v) { }
for (auto it = v.begin(); it != v.end(); ++it) { }
```

## std::map

```cpp
#include <map>

std::map<std::string, int> config;
config["port"] = 8080;
config["timeout"] = 30;

// Insert
config.insert({"host", "localhost"});
config.emplace("debug", 1);

// Lookup
if (auto it = config.find("port"); it != config.end()) {
    int port = it->second;
}

// Contains (C++20)
if (config.contains("port")) { }

// Iterate
for (const auto& [key, value] : config) {
    std::cout << key << " = " << value << "\n";
}
```

## std::string

```cpp
#include <string>

std::string s = "hello";
s += " world";
s.push_back('!');

s.size();
s.empty();
s.substr(0, 5);          // "hello"
s.find("world");          // index or npos
s.rfind("l");
s.replace(0, 5, "hi");

// C++20: starts_with / ends_with
s.starts_with("hello");   // true
s.ends_with("!");         // true

// Numeric conversions
int n = std::stoi("42");
double d = std::stod("3.14");
auto s = std::to_string(42);
```

## std::optional

```cpp
#include <optional>

std::optional<int> parse_port(const std::string& s) {
    try {
        int port = std::stoi(s);
        if (port > 0 && port <= 65535) return port;
    } catch (...) { }
    return std::nullopt;
}

auto port = parse_port("8080");
if (port) {
    std::cout << *port << "\n";
}
std::cout << port.value_or(8080) << "\n";
```

## std::variant

```cpp
#include <variant>

using Value = std::variant<int, double, std::string>;

Value v = 42;
v = 3.14;
v = "hello";

// Visit
std::visit([](const auto& val) {
    std::cout << val << "\n";
}, v);
```

## Algorithms

```cpp
#include <algorithm>
#include <numeric>

std::vector<int> v = {3, 1, 4, 1, 5, 9};

std::sort(v.begin(), v.end());
std::reverse(v.begin(), v.end());
std::find(v.begin(), v.end(), 4);
std::count(v.begin(), v.end(), 1);
std::accumulate(v.begin(), v.end(), 0);          // sum

// Transform
std::vector<int> squared;
std::transform(v.begin(), v.end(),
    std::back_inserter(squared),
    [](int x) { return x * x; });

// Filter with erase-remove idiom
v.erase(std::remove_if(v.begin(), v.end(),
    [](int x) { return x % 2 == 0; }), v.end());

// Min/max
auto [min, max] = std::minmax_element(v.begin(), v.end());
```

## Ranges (C++20)

```cpp
#include <ranges>

auto even = v | std::views::filter([](int x) { return x % 2 == 0; });
auto squared = v | std::views::transform([](int x) { return x * x; });

for (int x : v | std::views::reverse) { }
for (int x : v | std::views::take(3)) { }
```
