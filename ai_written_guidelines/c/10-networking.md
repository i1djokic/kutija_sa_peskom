# Networking

## TCP client

```c
#include <sys/socket.h>
#include <netdb.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

int tcp_connect(const char *host, const char *port) {
    struct addrinfo hints = {0}, *res;
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;

    int ret = getaddrinfo(host, port, &hints, &res);
    if (ret != 0) return -1;

    int fd = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
    if (fd < 0) { freeaddrinfo(res); return -1; }

    if (connect(fd, res->ai_addr, res->ai_addrlen) < 0) {
        close(fd); freeaddrinfo(res); return -1;
    }

    freeaddrinfo(res);
    return fd;
}

// Usage
int fd = tcp_connect("example.com", "80");
if (fd >= 0) {
    const char *req = "GET / HTTP/1.1\r\nHost: example.com\r\nConnection: close\r\n\r\n";
    send(fd, req, strlen(req), 0);

    char buf[4096];
    int n;
    while ((n = recv(fd, buf, sizeof(buf) - 1, 0)) > 0) {
        buf[n] = 0;
        printf("%s", buf);
    }
    close(fd);
}
```

## TCP server

```c
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>

int tcp_server(int port) {
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    if (fd < 0) return -1;

    int opt = 1;
    setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    struct sockaddr_in addr = {0};
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port = htons(port);

    if (bind(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        close(fd); return -1;
    }
    listen(fd, 10);
    return fd;
}

// Accept loop
int srv = tcp_server(8080);
if (srv >= 0) {
    struct sockaddr_in client;
    socklen_t len = sizeof(client);

    while (1) {
        int client_fd = accept(srv, (struct sockaddr *)&client, &len);
        if (client_fd >= 0) {
            char buf[1024];
            int n = recv(client_fd, buf, sizeof(buf) - 1, 0);
            buf[n] = 0;
            const char *resp = "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nOK";
            send(client_fd, resp, strlen(resp), 0);
            close(client_fd);
        }
    }
}
```

## UDP client

```c
int fd = socket(AF_INET, SOCK_DGRAM, 0);
struct sockaddr_in addr = {
    .sin_family = AF_INET,
    .sin_port = htons(9000),
};
inet_pton(AF_INET, "127.0.0.1", &addr.sin_addr);

sendto(fd, "ping", 4, 0, (struct sockaddr *)&addr, sizeof(addr));
char buf[64];
socklen_t len = sizeof(addr);
recvfrom(fd, buf, sizeof(buf), 0, (struct sockaddr *)&addr, &len);
```

## DNS resolution

```c
#include <netdb.h>

struct addrinfo hints = {0}, *res;
hints.ai_family = AF_UNSPEC;
hints.ai_socktype = SOCK_STREAM;

int ret = getaddrinfo("example.com", "80", &hints, &res);
if (ret == 0) {
    char host[256], service[64];
    getnameinfo(res->ai_addr, res->ai_addrlen,
                host, sizeof(host), service, sizeof(service),
                NI_NUMERICHOST);
    printf("IP: %s\n", host);  // "93.184.216.34"
    freeaddrinfo(res);
}
```

## Hostname lookup

```c
#include <unistd.h>

char hostname[256];
gethostname(hostname, sizeof(hostname));
printf("Host: %s\n", hostname);
```

## Port checker

```c
int port_open(const char *host, int port, int timeout_sec) {
    char port_str[8];
    snprintf(port_str, sizeof(port_str), "%d", port);
    int fd = tcp_connect(host, port_str);
    if (fd >= 0) {
        close(fd);
        return 1;
    }
    return 0;
}
```

## HTTP GET with libcurl

```c
// gcc -o program main.c -lcurl
#include <curl/curl.h>

size_t write_cb(void *data, size_t size, size_t nmemb, void *user) {
    fwrite(data, size, nmemb, (FILE *)user);
    return size * nmemb;
}

int main(void) {
    CURL *curl = curl_easy_init();
    if (!curl) return 1;

    curl_easy_setopt(curl, CURLOPT_URL, "http://example.com");
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_cb);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, stdout);
    curl_easy_setopt(curl, CURLOPT_TIMEOUT, 10L);

    CURLcode res = curl_easy_perform(curl);
    if (res != CURLE_OK)
        fprintf(stderr, "curl: %s\n", curl_easy_strerror(res));

    curl_easy_cleanup(curl);
    return 0;
}
```
