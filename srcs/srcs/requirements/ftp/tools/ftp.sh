#!/bin/sh

FTP_PASSWORD=$(cat /run/secrets/ftp_password)

useradd -m ${FTP_USER}
echo "${FTP_USER}:${FTP_PASSWORD}" | chpasswd
mkdir -p /var/run/vsftpd/empty

exec vsftpd /etc/vsftpd.conf
