FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends php-cli php-mysql ca-certificates curl \
    && mkdir -p /var/www \
    && curl -Lo /var/www/index.php \
       https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php \
    && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["php", "-S", "0.0.0.0:8080", "-t", "/var/www"]
