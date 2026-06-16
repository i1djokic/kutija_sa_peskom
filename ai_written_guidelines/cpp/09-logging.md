# Logging

## spdlog (recommended)

```bash
# Conan: spdlog/1.13.0
# vcpkg: spdlog
```

```cpp
#include <spdlog/spdlog.h>
#include <spdlog/sinks/stdout_color_sinks.h>
#include <spdlog/sinks/rotating_file_sink.h>
#include <spdlog/sinks/basic_file_sink.h>

// Basic usage
spdlog::info("Welcome to myapp!");
spdlog::warn("Disk space low: {:.1f}%", pct);
spdlog::error("Connection failed: {}", strerror(errno));
spdlog::debug("Loaded {} config entries", count);

// With logger object
auto logger = spdlog::stdout_color_mt("console");
logger->info("Server started on port {}", port);

// File + console
auto console = spdlog::stdout_color_mt("console");
auto file = spdlog::rotating_logger_mt("file", "app.log", 1048576 * 5, 3);

// Combine sinks
std::vector<spdlog::sink_ptr> sinks;
sinks.push_back(std::make_shared<spdlog::sinks::stdout_color_sink_mt>());
sinks.push_back(std::make_shared<spdlog::sinks::rotating_file_sink_mt>(
    "app.log", 1048576 * 5, 3));

auto logger = std::make_shared<spdlog::logger>("app", sinks.begin(), sinks.end());
spdlog::register_logger(logger);
```

### Configuration

```cpp
// Log level
spdlog::set_level(spdlog::level::debug);
logger->set_level(spdlog::level::info);

// Format
spdlog::set_pattern("[%Y-%m-%d %H:%M:%S] [%^%l%$] [%n] %v");
// %Y-%m-%d %H:%M:%S  timestamp
// %^...%$            color range
// %l                 log level
// %n                 logger name
// %v                 actual message

// Flush on critical
spdlog::flush_on(spdlog::level::critical);
```

## std::print / std::format logging (C++20/23)

```cpp
#include <print>   // C++23
#include <chrono>

template <typename... Args>
void log_info(std::format_string<Args...> fmt, Args&&... args) {
    auto now = std::chrono::system_clock::now();
    std::print(stderr, "[{::%Y-%m-%d %H:%M:%S}] [INFO] ",
               std::chrono::floor<std::chrono::seconds>(now));
    std::println(stderr, fmt, std::forward<Args>(args)...);
}
```

## Simple logger class (no external deps)

```cpp
#include <fstream>
#include <source_location>  // C++20
#include <chrono>
#include <format>           // C++20

enum class LogLevel { Debug, Info, Warn, Error };

class Logger {
public:
    explicit Logger(std::string name)
        : name_(std::move(name)) {
        auto now = std::chrono::system_clock::now();
        file_.open(name_ + ".log", std::ios::app);
    }

    template <typename... Args>
    void log(LogLevel level,
             std::format_string<Args...> fmt,
             Args&&... args,
             std::source_location loc = std::source_location::current()) {
        if (level < min_level_) return;

        auto now = std::chrono::system_clock::now();
        auto time = std::chrono::floor<std::chrono::seconds>(now);

        auto msg = std::format("[{:%Y-%m-%d %H:%M:%S}] [{}] {}:{}:{} ",
                               time, level_name(level),
                               loc.file_name(), loc.line(), loc.function_name());
        msg += std::format(fmt, std::forward<Args>(args)...);

        std::println(std::cerr, "{}", msg);
        if (file_.is_open())
            file_ << msg << std::flush;
    }

    void set_level(LogLevel level) { min_level_ = level; }

private:
    static std::string_view level_name(LogLevel level) {
        switch (level) {
            case LogLevel::Debug: return "DEBUG";
            case LogLevel::Info:  return "INFO";
            case LogLevel::Warn:  return "WARN";
            case LogLevel::Error: return "ERROR";
        }
        return "UNKNOWN";
    }

    std::string name_;
    std::ofstream file_;
    LogLevel min_level_ = LogLevel::Info;
};
```
