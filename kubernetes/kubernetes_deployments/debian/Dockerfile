FROM debian:latest

RUN apt-get update && apt-get install -y --no-install-recommends \
    iputils-ping \
    telnet \
    netcat-openbsd \
    dnsutils \
    traceroute \
    curl \
    wget \
    net-tools \
    iproute2 \
    procps \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

CMD ["sleep", "infinity"]
