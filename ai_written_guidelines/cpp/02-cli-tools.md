# CLI Tools

## CLI11 (recommended)

```bash
# Conan: cli11/2.4.2
# vcpkg: cli11
# Header-only: include "CLI/CLI11.hpp"
```

```cpp
#include <CLI/CLI.hpp>

int main(int argc, char* argv[]) {
    CLI::App app{"Deployment automation tool"};

    std::string target;
    std::string env = "development";
    int port = 8080;
    bool dry_run = false;
    bool verbose = false;

    app.add_option("target", target, "Deployment target")->required();
    app.add_option("-e,--env", env, "Environment");
    app.add_option("-p,--port", port, "Port number");
    app.add_flag("--dry-run", dry_run, "Simulate without changing");
    app.add_flag("-v,--verbose", verbose, "Verbose output");

    CLI11_PARSE(app, argc, argv);

    std::cout << "Deploying " << target << " to " << env << "\n";
    return 0;
}
```

### Subcommands

```cpp
CLI::App app{"Automation tool"};

auto* deploy = app.add_subcommand("deploy", "Deploy application");
auto* restart = app.add_subcommand("restart", "Restart service");
app.require_subcommand(1);

std::string env;
deploy->add_option("-e,--env", env, "Environment")->required();

std::string service;
restart->add_option("service", service, "Service name")->required();

CLI11_PARSE(app, argc, argv);

if (*deploy) { /* deploy logic */ }
if (*restart) { /* restart logic */ }
```

## argparse (single-header, C++17)

```bash
# https://github.com/p-ranav/argparse
```

```cpp
#include <argparse/argparse.hpp>

int main(int argc, char* argv[]) {
    argparse::ArgumentParser program("deploy");

    program.add_argument("target")
        .help("deployment target");

    program.add_argument("-e", "--env")
        .default_value("development")
        .help("environment");

    program.add_argument("-v", "--verbose")
        .default_value(false)
        .implicit_value(true);

    try {
        program.parse_args(argc, argv);
    } catch (const std::exception& e) {
        std::cerr << e.what() << "\n";
        return 1;
    }

    auto target = program.get<std::string>("target");
    auto env = program.get<std::string>("-e");
    return 0;
}
```

## getopt (POSIX, stdlib)

```cpp
#include <getopt.h>

int main(int argc, char* argv[]) {
    int verbose = 0;
    int port = 8080;
    std::string host = "localhost";

    static option long_opts[] = {
        {"verbose", no_argument, &verbose, 1},
        {"host",    required_argument, 0, 'h'},
        {"port",    required_argument, 0, 'p'},
        {0, 0, 0, 0}
    };

    int opt;
    while ((opt = getopt_long(argc, argv, "vh:p:", long_opts, nullptr)) != -1) {
        switch (opt) {
        case 'h': host = optarg; break;
        case 'p': port = std::stoi(optarg); break;
        case 'v': verbose = 1; break;
        }
    }

    std::cout << "Connecting to " << host << ":" << port << "\n";
    return 0;
}
```

## Exit codes

```cpp
enum ExitCode : int {
    SUCCESS = 0,
    FAILURE = 1,
    CONFIG_ERROR = 2,
    NETWORK_ERROR = 3,
};
```

## Environment variables

```cpp
#include <cstdlib>

const char* env_host = std::getenv("HOST");
std::string host = env_host ? env_host : "localhost";

// C++11: portable check
bool debug = std::getenv("DEBUG") != nullptr;
```
