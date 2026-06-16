# Object-Oriented Programming

## Class basics

```cpp
class Service {
public:
    Service(std::string name, std::string host = "localhost")
        : name_(std::move(name)), host_(std::move(host)) {}

    virtual void start() {
        running_ = true;
        std::cout << name_ << " started on " << host_ << "\n";
    }

    virtual void stop() {
        running_ = false;
    }

    [[nodiscard]] bool is_running() const { return running_; }

private:
    std::string name_;
    std::string host_;
    bool running_ = false;
};
```

## Inheritance

```cpp
class HTTPService : public Service {
public:
    HTTPService(std::string name, std::string host = "localhost", int port = 8080)
        : Service(std::move(name), std::move(host)), port_(port) {}

    void start() override {
        Service::start();
        std::cout << "Listening on port " << port_ << "\n";
    }

private:
    int port_;
};
```

## Polymorphism

```cpp
std::vector<std::unique_ptr<Service>> services;
services.push_back(std::make_unique<HTTPService>("web"));
services.push_back(std::make_unique<Service>("worker"));

for (auto& svc : services) {
    svc->start();  // virtual dispatch
}
```

## Rule of Five

```cpp
class Resource {
public:
    // Constructor
    Resource(size_t size) : data_(new char[size]), size_(size) {}

    // Destructor
    ~Resource() { delete[] data_; }

    // Copy constructor
    Resource(const Resource& other)
        : data_(new char[other.size_]), size_(other.size_) {
        std::copy(other.data_, other.data_ + size_, data_);
    }

    // Copy assignment
    Resource& operator=(const Resource& other) {
        if (this != &other) {
            delete[] data_;
            size_ = other.size_;
            data_ = new char[size_];
            std::copy(other.data_, other.data_ + size_, data_);
        }
        return *this;
    }

    // Move constructor
    Resource(Resource&& other) noexcept
        : data_(std::exchange(other.data_, nullptr))
        , size_(std::exchange(other.size_, 0)) {}

    // Move assignment
    Resource& operator=(Resource&& other) noexcept {
        if (this != &other) {
            delete[] data_;
            data_ = std::exchange(other.data_, nullptr);
            size_ = std::exchange(other.size_, 0);
        }
        return *this;
    }

private:
    char* data_;
    size_t size_;
};
```

## Rule of Zero (prefer this)

```cpp
// Use RAII types as members; compiler-generated special members work
class Service {
    std::string name_;
    std::unique_ptr<Logger> logger_;
    std::vector<int> ports_;
};
```

## Abstract base class

```cpp
class Runner {
public:
    virtual ~Runner() = default;
    virtual int run(const std::string& command) = 0;
};

class LocalRunner : public Runner {
public:
    int run(const std::string& command) override {
        return std::system(command.c_str());
    }
};
```

## Composition over Inheritance

```cpp
class HealthChecker {
public:
    bool check() { return true; }
};

class MetricsCollector {
public:
    std::map<std::string, double> collect() { return {}; }
};

class MonitoringService {
    HealthChecker health_;
    MetricsCollector metrics_;
public:
    void run() {
        if (health_.check()) {
            auto data = metrics_.collect();
            // ...
        }
    }
};
```
