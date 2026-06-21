FROM debian:bookworm

RUN apt-get update && apt-get install -y mariadb-server

COPY conf/mariadb-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY tools/mariadb.sh /

ENTRYPOINT ["sh", "/mariadb.sh"]