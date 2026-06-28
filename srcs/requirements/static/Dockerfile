FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates nginx git \
    && git clone https://github.com/mertilhans/portfolio /var/www/html/portfolio \
    && rm -rf /var/www/html/portfolio/.git /var/lib/apt/lists/*

COPY conf/default.conf /etc/nginx/sites-enabled/default

ENTRYPOINT ["nginx", "-g", "daemon off;"]
