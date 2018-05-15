#!/bin/bash

if [ -z "$NGINX_SERVER_NAME" ]
then
	echo "NGINX_SERVER_NAME is not set, not creating/renewing cert."
	exit -1
fi

if [ -z "$NGINX_CERT_EMAIL" ]
then
	echo "NGINX_CERT_EMAIL is not set, not creating/renewing cert."
	exit -1
fi

if [ -z "$NGINX_WEBROOT_PATH" ]
then
	export  NGINX_WEBROOT_PATH="/webroot"
fi


if [ "$1" = "--renew" ]
then
  certbot renew
  exit_code=$?
else
  certbot --authenticator webroot --installer nginx -d ${NGINX_SERVER_NAME} \
-m ${NGINX_CERT_EMAIL}  --agree-tos -n --webroot-path "$NGINX_WEBROOT_PATH" \
--redirect
  exit_code=$?
fi

exit $exit_code