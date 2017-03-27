#!/bin/bash

set -e

SYS_DOMAIN=$1
APP_DOMAIN=$2

certs=`dirname $0`/certs

rm -rf $certs && mkdir -p $certs

cd $certs

echo "Generating CA..."
openssl genrsa -out ca.key 2048
yes "" | openssl req -x509 -new -sha256 -nodes -key ca.key \
	-out ca.crt -days 99999

name="director"

cat >openssl-exts.conf <<-EOL
extensions = san
[san]
subjectAltName = @alt_names
[alt_names]
DNS.1 = *.${SYS_DOMAIN}
DNS.2 = *.login.${SYS_DOMAIN}
DNS.3 = *.uaa.${SYS_DOMAIN}
DNS.4 = *.${APP_DOMAIN}
EOL

echo "Generating certificate signing request for ${SYS_DOMAIN}..."
# golang requires to have SAN for the IP
openssl req -new -sha256 -nodes -newkey rsa:2048 \
	-out ${name}.csr -keyout ${name}.key \
	-subj "/C=JP/O=BOSH"

 cat ./openssl-exts.conf

echo "Generating certificate ..."
openssl x509 -req -sha256 -in ${name}.csr \
	-CA ca.crt -CAkey ca.key -CAcreateserial \
	-out ${name}.crt -days 99999 \
	-extfile ./openssl-exts.conf

echo "Deleting certificate signing request and config..."
rm ${name}.csr
rm ./openssl-exts.conf

echo "Finished..."
ls -la .
