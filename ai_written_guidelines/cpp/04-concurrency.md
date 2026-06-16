# Concurrency

## std::thread

```cpp
#include <thread>
#include <iostream>

void worker(int id) {
    std::cout << "Worker " << id << " started\n";
}

std::vector<std::thread> threads;
for (int i = 0; i < 4; i++) {
    threads.emplace_back(worker, i);
}
for (auto& t : threads) {
    t.join();
}
```

## Mutex and locks

```cpp
#include <mutex>

std::mutex mtx;
int counter = 0;

// std::lock_guard (RAII, scoped)
{
    std::lock_guard<std::mutex> lock(mtx);
    counter++;
}

// std::unique_lock (more flexible)
std::unique_lock<std::mutex> lock(mtx, std::defer_lock);
// ... do stuff ...
lock.lock();
counter++;
lock.unlock();
```

## std::async

```cpp
#include <future>

int fetch_data(const std::string& url) {
    // ... blocking I/O ...
    return 42;
}

auto future = std::async(std::launch::async, fetch_data, "http://example.com");
// ... do other work ...
int result = future.get();  // blocks until ready

// Multiple async tasks
std::vector<std::future<int>> futures;
for (const auto& url : urls) {
    futures.push_back(std::async(std::launch::async, fetch_data, url));
}
for (auto& f : futures) {
    results.push_back(f.get());
}
```

## std::future with std::promise

```cpp
std::promise<int> promise;
auto future = promise.get_future();

std::thread t([&promise] {
    promise.set_value(42);
});

int result = future.get();
t.join();
```

## Thread pool (simple)

```cpp
#include <queue>
#include <functional>
#include <condition_variable>

class ThreadPool {
public:
    ThreadPool(size_t num_threads) {
        for (size_t i = 0; i < num_threads; i++) {
            workers_.emplace_back([this] {
                while (true) {
                    std::function<void()> task;
                    {
                        std::unique_lock lock(queue_mutex_);
                        condition_.wait(lock, [this] {
                            return !tasks_.empty() || stop_;
                        });
                        if (stop_ && tasks_.empty()) return;
                        task = std::move(tasks_.front());
                        tasks_.pop();
                    }
                    task();
                }
            });
        }
    }

    template<typename F>
    void enqueue(F&& f) {
        {
            std::lock_guard lock(queue_mutex_);
            tasks_.emplace(std::forward<F>(f));
        }
        condition_.notify_one();
    }

    ~ThreadPool() {
        {
            std::lock_guard lock(queue_mutex_);
            stop_ = true;
        }
        condition_.notify_all();
        for (auto& t : workers_) t.join();
    }

private:
    std::vector<std::thread> workers_;
    std::queue<std::function<void()>> tasks_;
    std::mutex queue_mutex_;
    std::condition_variable condition_;
    bool stop_ = false;
};
```

## std::atomic

```cpp
#include <atomic>

std::atomic<int> counter{0};

void increment() {
    counter.fetch_add(1);  // thread-safe
    counter++;             // also atomic for integers
}

// Common operations
counter.load();           // read
counter.store(10);        // write
counter.exchange(5);      // atomic swap
counter.compare_exchange_weak(expected, desired);
```

## When to use what

| Tool | Best for |
|------|----------|
| `std::thread` | Long-running concurrent tasks |
| `std::async` | Simple fire-and-wait parallelism |
| `std::future`/`promise` | One-shot value passing |
| Thread pool | Many short tasks |
| `std::atomic` | Simple counters, flags |
| `std::mutex` + `lock_guard` | Protecting shared data |
| `std::condition_variable` | Producer-consumer patterns |
