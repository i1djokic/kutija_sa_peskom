# Date & Time

## std::chrono (C++11, extended in C++20)

```cpp
#include <chrono>
#include <iostream>

namespace ch = std::chrono;

// Clocks
auto now = ch::system_clock::now();         // system time
auto steady = ch::steady_clock::now();      // monotonic
auto high_res = ch::high_resolution_clock::now();

// Durations
auto ms = ch::milliseconds(1000);
auto sec = ch::seconds(1);
auto min = ch::minutes(1);
auto hours = ch::hours(1);

// Arithmetic
auto later = now + ch::minutes(30);
auto diff = later - now;
std::cout << ch::duration_cast<ch::seconds>(diff).count() << "s\n";
```

## Timing / measuring

```cpp
auto start = ch::steady_clock::now();
// ... work ...
auto end = ch::steady_clock::now();

auto elapsed = ch::duration_cast<ch::milliseconds>(end - start);
std::cout << "Elapsed: " << elapsed.count() << "ms\n";
```

## std::chrono formatting (C++20)

```cpp
#include <chrono>
#include <format>

auto now = ch::system_clock::now();
auto time = ch::floor<ch::seconds>(now);

// Format
std::cout << std::format("{:%Y-%m-%d %H:%M:%S}", time) << "\n";
// "2025-06-15 14:30:00"

// ISO 8601
std::cout << std::format("{:%FT%TZ}", time) << "\n";
// "2025-06-15T14:30:00Z"
```

## Time point to time_t

```cpp
auto now = ch::system_clock::now();
std::time_t tt = ch::system_clock::to_time_t(now);
std::cout << "Timestamp: " << tt << "\n";

// Back to time_point
auto tp = ch::system_clock::from_time_t(tt);
```

## Duration literals (C++14)

```cpp
using namespace std::chrono_literals;

auto d1 = 5s;        // 5 seconds
auto d2 = 100ms;     // 100 milliseconds
auto d3 = 2h + 30min;
auto d4 = 1ns;
```

## Sleep

```cpp
#include <thread>

std::this_thread::sleep_for(std::chrono::seconds(1));
std::this_thread::sleep_for(std::chrono::milliseconds(500));
std::this_thread::sleep_until(ch::system_clock::now() + ch::minutes(5));
```

## Scheduling with std::chrono

```cpp
#include <thread>
#include <chrono>
#include <functional>
#include <atomic>

class PeriodicTask {
public:
    PeriodicTask(std::chrono::milliseconds interval, std::function<void()> task)
        : interval_(interval), task_(std::move(task)) {}

    void start() {
        running_ = true;
        thread_ = std::thread([this] {
            auto next = std::chrono::steady_clock::now();
            while (running_) {
                task_();
                next += interval_;
                std::this_thread::sleep_until(next);
            }
        });
    }

    void stop() {
        running_ = false;
        if (thread_.joinable()) thread_.join();
    }

private:
    std::chrono::milliseconds interval_;
    std::function<void()> task_;
    std::thread thread_;
    std::atomic<bool> running_{false};
};
```

## Calendar dates

```cpp
#include <chrono>

// C++20: year_month_day
using namespace std::chrono;

auto today = floor<days>(system_clock::now());
auto ymd = year_month_day{today};

std::cout << int(ymd.year()) << "-"
          << unsigned(ymd.month()) << "-"
          << unsigned(ymd.day()) << "\n";

// Date arithmetic
auto tomorrow = today + days(1);
auto next_week = today + weeks(1);
auto next_month = today + months{1};

// Difference in days
auto d1 = sys_days{2025_y/June/15};
auto d2 = sys_days{2025_y/December/31};
auto diff = (d2 - d1).count();
std::cout << diff << " days\n";
```

## Timer (asio)

```cpp
#include <boost/asio.hpp>

boost::asio::io_context io;
boost::asio::steady_timer timer(io, boost::asio::chrono::seconds(5));

timer.async_wait([](auto ec) {
    if (!ec) std::cout << "Timer fired\n";
});

io.run();  // blocks until timer expires
```
