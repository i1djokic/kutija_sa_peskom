# Networking

## HTTP client (reqwest)

```toml
[dependencies]
reqwest = { version = "0.12", features = ["json"] }
tokio = { version = "1", features = ["full"] }
```

```rust
use reqwest;
use serde::{Deserialize, Serialize};

#[derive(Serialize)]
struct DeployRequest {
    env: String,
    version: String,
}

#[derive(Deserialize)]
struct DeployResponse {
    status: String,
    job_id: String,
}

async fn deploy(env: &str, version: &str) -> Result<DeployResponse, reqwest::Error> {
    let client = reqwest::Client::new();
    let resp = client.post("https://api.example.com/deploy")
        .json(&DeployRequest {
            env: env.into(),
            version: version.into(),
        })
        .send()
        .await?;

    let result: DeployResponse = resp.json().await?;
    Ok(result)
}
```

### GET with error handling

```rust
async fn health_check(url: &str) -> Result<bool, reqwest::Error> {
    let client = reqwest::Client::builder()
        .timeout(Duration::from_secs(5))
        .build()?;

    let resp = client.get(url).send().await?;

    Ok(resp.status().is_success())
}
```

## TCP client

```rust
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::TcpStream;

async fn tcp_client() -> Result<()> {
    let mut stream = TcpStream::connect("127.0.0.1:8080").await?;

    let request = b"GET / HTTP/1.1\r\nHost: localhost\r\n\r\n";
    stream.write_all(request).await?;

    let mut buf = vec![0u8; 4096];
    let n = stream.read(&mut buf).await?;
    println!("{}", String::from_utf8_lossy(&buf[..n]));

    Ok(())
}
```

## TCP server

```rust
use tokio::net::TcpListener;
use tokio::io::{AsyncReadExt, AsyncWriteExt};

#[tokio::main]
async fn main() -> Result<()> {
    let listener = TcpListener::bind("0.0.0.0:8080").await?;

    loop {
        let (mut socket, addr) = listener.accept().await?;
        println!("New connection: {}", addr);

        tokio::spawn(async move {
            let mut buf = [0; 1024];
            match socket.read(&mut buf).await {
                Ok(n) if n > 0 => {
                    let response = b"HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nOK";
                    socket.write_all(response).await.unwrap();
                }
                _ => {}
            }
        });
    }
}
```

## DNS

```rust
use std::net::ToSocketAddrs;

fn resolve(host: &str) -> Result<Vec<std::net::SocketAddr>> {
    let addrs: Vec<_> = (host, 0).to_socket_addrs()?.collect();
    Ok(addrs)
}

// With tokio
use tokio::net::lookup_host;

#[tokio::main]
async fn main() -> Result<()> {
    let ips = lookup_host("example.com:80").await?;
    for ip in ips {
        println!("{}", ip);
    }
    Ok(())
}
```

## Port checker

```rust
use tokio::net::TcpStream;
use tokio::time::{timeout, Duration};

async fn port_open(host: &str, port: u16) -> bool {
    let addr = format!("{}:{}", host, port);
    timeout(Duration::from_secs(2), TcpStream::connect(&addr))
        .await
        .is_ok()
}

async fn scan_ports(host: &str, ports: &[u16]) {
    let mut tasks = vec![];
    for &port in ports {
        let host = host.to_string();
        tasks.push(tokio::spawn(async move {
            if port_open(&host, port).await {
                println!("Port {} open", port);
            }
        }));
    }
    for task in tasks {
        task.await.unwrap();
    }
}
```

## Ping (via subprocess)

```rust
use std::process::Command;

fn ping(host: &str, count: u32) -> Result<bool> {
    let output = Command::new("ping")
        .arg("-c")
        .arg(count.to_string())
        .arg("-W")
        .arg("2")
        .arg(host)
        .output()?;
    Ok(output.status.success())
}
```
