FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends vsftpd \
    && rm -rf /var/lib/apt/lists/*

COPY conf/vsftpd.conf /etc/vsftpd.conf
COPY tools/ftp.sh /ftp.sh

ENTRYPOINT ["sh", "/ftp.sh"]
