# File I/O & Filesystem

## fstream

```cpp
#include <fstream>
#include <string>

// Read entire file
std::ifstream file("config.yaml");
std::string content((std::istreambuf_iterator<char>(file)),
                     std::istreambuf_iterator<char>());

// Read line by line
std::ifstream file("log.txt");
std::string line;
while (std::getline(file, line)) {
    std::cout << line << "\n";
}

// Write
std::ofstream out("output.txt");
out << "hello world\n";
out << "port: " << 8080 << "\n";

// Append
std::ofstream log("app.log", std::ios::app);
log << "event logged\n";

// Binary
std::ifstream binary("data.bin", std::ios::binary);
char buf[1024];
binary.read(buf, sizeof(buf));
size_t n = binary.gcount();
```

## std::filesystem (C++17)

```cpp
#include <filesystem>
namespace fs = std::filesystem;

// Path
fs::path p = "data/config.yaml";
p.filename();         // "config.yaml"
p.stem();             // "config"
p.extension();        // ".yaml"
p.parent_path();      // "data"
p.absolute();         // full absolute path

// File info
fs::exists(p);
fs::is_regular_file(p);
fs::is_directory(p);
fs::file_size(p);     // in bytes
fs::last_write_time(p);

// Directory iteration
for (const auto& entry : fs::directory_iterator(".")) {
    if (entry.is_regular_file()) {
        std::cout << entry.path() << "\n";
    }
}

// Recursive
for (const auto& entry : fs::recursive_directory_iterator("src")) {
    std::cout << entry.path() << "\n";
}

// Create / remove
fs::create_directory("output");
fs::create_directories("output/logs/2025");  // recursive
fs::remove("temp.txt");
fs::remove_all("temp_dir");
fs::rename("old.txt", "new.txt");

// Copy
fs::copy("src.txt", "dst.txt");
fs::copy("src/", "dst/", fs::copy_options::recursive);

// Temp
auto tmp = fs::temp_directory_path() / "myapp_XXXXXX";
// create directory with mkdtemp equivalent
```

## String streams

```cpp
#include <sstream>

std::ostringstream oss;
oss << "host=" << host << " port=" << port;
std::string result = oss.str();

// Parse
std::istringstream iss("8080 30");
int port, timeout;
iss >> port >> timeout;
```

## Reading files into containers

```cpp
// Read all lines
std::vector<std::string> lines;
std::string line;
while (std::getline(file, line)) {
    lines.push_back(line);
}

// Read into string
std::string content(
    std::istreambuf_iterator<char>(file),
    {}
);
```
