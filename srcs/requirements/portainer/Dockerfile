FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl \
    && curl -Lo /tmp/portainer.tar.gz \
       https://github.com/portainer/portainer/releases/download/2.21.4/portainer-2.21.4-linux-amd64.tar.gz \
    && tar xzf /tmp/portainer.tar.gz -C /opt \
    && rm -rf /tmp/portainer.tar.gz /var/lib/apt/lists/*

ENTRYPOINT ["/opt/portainer/portainer"]
CMD ["--host=unix:///var/run/docker.sock", "--base-url=/portainer"]
