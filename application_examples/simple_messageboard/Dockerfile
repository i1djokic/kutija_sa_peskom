FROM ubuntu:24.04

RUN useradd -m -u 1001 appuser \
    && apt-get update \
    && apt-get install -y nginx python3 python3-pip \
    && pip3 install --break-system-packages pymysql \
    && mkdir -p /run/nginx /usr/share/nginx/html /app /var/log/nginx /var/lib/nginx/logs /var/lib/nginx/tmp /var/lib/nginx/body \
    && chown -R appuser:appuser /run/nginx /usr/share/nginx/html /app /var/lib/nginx /var/log/nginx \
    && rm -rf /var/lib/apt/lists/*

COPY nginx/config.conf /etc/nginx/nginx.conf
COPY src /usr/share/nginx/html
COPY server.py /app/server.py

EXPOSE 80

USER appuser

CMD nginx -g 'daemon off;' & exec python3 /app/server.py
