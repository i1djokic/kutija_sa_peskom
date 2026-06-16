# Networking

## Boost.Asio (TCP client)

```cpp
// Conan: boost/1.84.0
#include <boost/asio.hpp>
#include <iostream>

namespace asio = boost::asio;
using tcp = asio::ip::tcp;

std::string http_get(const std::string& host, const std::string& port) {
    asio::io_context ctx;
    tcp::resolver resolver(ctx);
    tcp::socket socket(ctx);

    asio::connect(socket, resolver.resolve(host, port));

    asio::write(socket, asio::buffer(
        "GET / HTTP/1.1\r\nHost: " + host + "\r\nConnection: close\r\n\r\n"));

    std::string response;
    asio::error_code ec;
    asio::read(socket, asio::dynamic_buffer(response), ec);

    return response;
}
```

### TCP server

```cpp
asio::io_context ctx;
tcp::acceptor acceptor(ctx, tcp::endpoint(tcp::v4(), 8080));

while (true) {
    tcp::socket socket(ctx);
    acceptor.accept(socket);

    std::string response = "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nOK";
    asio::write(socket, asio::buffer(response));
}
```

## POSIX sockets (C-style, portable)

```cpp
#include <sys/socket.h>
#include <netdb.h>
#include <unistd.h>
#include <cstring>

class TCPSocket {
    int fd_ = -1;
public:
    TCPSocket() = default;

    bool connect(const std::string& host, int port) {
        addrinfo hints{}, *res;
        hints.ai_family = AF_UNSPEC;
        hints.ai_socktype = SOCK_STREAM;

        std::string port_str = std::to_string(port);
        if (getaddrinfo(host.c_str(), port_str.c_str(), &hints, &res) != 0)
            return false;

        fd_ = ::socket(res->ai_family, res->ai_socktype, res->ai_protocol);
        if (fd_ < 0) { freeaddrinfo(res); return false; }

        if (::connect(fd_, res->ai_addr, res->ai_addrlen) < 0) {
            close();
            freeaddrinfo(res);
            return false;
        }

        freeaddrinfo(res);
        return true;
    }

    std::string read() {
        char buf[4096] = {};
        ssize_t n = ::recv(fd_, buf, sizeof(buf) - 1, 0);
        if (n > 0) return {buf, static_cast<size_t>(n)};
        return {};
    }

    void write(const std::string& data) {
        ::send(fd_, data.data(), data.size(), 0);
    }

    void close() {
        if (fd_ >= 0) { ::close(fd_); fd_ = -1; }
    }

    ~TCPSocket() { close(); }
    TCPSocket(const TCPSocket&) = delete;
    TCPSocket& operator=(const TCPSocket&) = delete;
};
```

## cURL wrapper (C++)

```cpp
// link with -lcurl
#include <curl/curl.h>
#include <string>
#include <functional>

class HTTPClient {
    CURL* curl_;
public:
    HTTPClient() { curl_ = curl_easy_init(); }
    ~HTTPClient() { curl_easy_cleanup(curl_); }

    std::string get(const std::string& url, int timeout = 10) {
        std::string response;

        curl_easy_setopt(curl_, CURLOPT_URL, url.c_str());
        curl_easy_setopt(curl_, CURLOPT_TIMEOUT, timeout);
        curl_easy_setopt(curl_, CURLOPT_WRITEFUNCTION,
            +[](void* data, size_t size, size_t nmemb, void* user) -> size_t {
                auto* resp = static_cast<std::string*>(user);
                resp->append(static_cast<char*>(data), size * nmemb);
                return size * nmemb;
            });
        curl_easy_setopt(curl_, CURLOPT_WRITEDATA, &response);

        curl_easy_perform(curl_);
        return response;
    }
};
```

## Port checker

```cpp
bool port_open(const std::string& host, int port, int timeout_sec = 2) {
    asio::io_context ctx;
    tcp::socket socket(ctx);
    asio::error_code ec;

    socket.connect({asio::ip::make_address(host),
                    static_cast<unsigned short>(port)}, ec);

    if (!ec) socket.close();
    return !ec;
}
```
