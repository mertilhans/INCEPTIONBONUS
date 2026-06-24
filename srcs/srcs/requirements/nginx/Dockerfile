FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends nginx openssl \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /etc/nginx/ssl

COPY ./conf/nginx.conf /etc/nginx/sites-enabled/default
COPY ./tools/nginx.sh /tmp/nginx.sh

RUN chmod +x /tmp/nginx.sh

ENTRYPOINT ["/tmp/nginx.sh"]