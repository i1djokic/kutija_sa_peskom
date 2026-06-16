# Memory Management

## RAII (Resource Acquisition Is Initialization)

Resources are acquired during construction and released during destruction.

```cpp
class FileHandle {
    FILE* fp_;
public:
    FileHandle(const char* path, const char* mode) {
        fp_ = fopen(path, mode);
        if (!fp_) throw std::runtime_error("Cannot open file");
    }
    ~FileHandle() { if (fp_) fclose(fp_); }

    FileHandle(const FileHandle&) = delete;
    FileHandle& operator=(const FileHandle&) = delete;

    void write(const std::string& data) {
        fwrite(data.data(), 1, data.size(), fp_);
    }
};
```

## Smart pointers

```cpp
#include <memory>

// unique_ptr (exclusive ownership)
auto ptr = std::make_unique<int>(42);
*ptr = 10;

// Transfer ownership
auto ptr2 = std::move(ptr);
if (!ptr) { /* ptr is null */ }

// Custom deleter
auto file = std::unique_ptr<FILE, decltype(&fclose)>(
    fopen("test.txt", "r"), &fclose);

// shared_ptr (shared ownership)
auto sptr = std::make_shared<Service>("web");
auto sptr2 = sptr;  // reference count = 2
sptr.reset();       // ref count = 1

// weak_ptr (non-owning observer)
std::weak_ptr<Service> wptr = sptr;
if (auto locked = wptr.lock()) {
    locked->start();  // access if still alive
}
```

## Move semantics

```cpp
// Move constructor transfers resources (cheap)
std::vector<int> v1 = {1, 2, 3, 4, 5};
std::vector<int> v2 = std::move(v1);  // v1 is now empty

// Move assignment
v1 = std::move(v2);

// In functions
void process(std::vector<int> v);         // copy
void process(std::vector<int>&& v);       // move (rvalue reference)
```

## std::exchange and std::swap

```cpp
auto old = std::exchange(ptr, nullptr);  // set ptr to null, return old value
std::swap(a, b);                          // swap two values
```

## Placement new

```cpp
// Construct object in pre-allocated memory
alignas(Service) unsigned char buffer[sizeof(Service)];
Service* svc = new (buffer) Service("web");
svc->start();
svc->~Service();  // explicit destructor call
```

## Avoiding raw `new`/`delete`

```cpp
// Bad
auto ptr = new Service("web");
delete ptr;

// Good
auto ptr = std::make_unique<Service>("web");
// No delete needed
```

## Containers of pointers

```cpp
// Owned
std::vector<std::unique_ptr<Service>> services;
services.push_back(std::make_unique<HTTPService>("web"));

// Non-owning
std::vector<Service*> observers;
observers.push_back(services[0].get());
```
