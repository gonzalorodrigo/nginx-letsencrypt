#!/bin/bash

get_env_vars() {
	var_list=$( printenv | cut -d= -f1 )
	for v in $var_list
	do
		echo \$$v
	done
}

if [ -z "$NGINX_FRONTEND_URL" ]
then
	export NGINX_FRONTEND_URL="http://web-frontend:80"
fi
if [ -z "$NGINX_IMAGE_SERVER_URL" ]
then
	export NGINX_IMAGE_SERVER_URL="http://web-imageserver:80"
fi
if [ -z "$NGINX_BACKEND_URL" ]
then
	export NGINX_BACKEND_URL="http://web-backend:8000"
fi
if [ -z "$NGINX_FRONTEND_LOCATION" ]
then
	export NGINX_FRONTEND_LOCATION="/"
fi
if [ -z "$NGINX_IMAGE_SERVER_LOCATION" ]
then
	export NGINX_IMAGE_SERVER_LOCATION="/images/"
fi
if [ -z "$NGINX_BACKEND_LOCATION" ]
then
	export NGINX_BACKEND_LOCATION="/backend/"
fi

if [ -z "$NGINX_SERVER_NAME" ]
then
	export NGINX_SERVER_NAME="localhost"
fi

template_file="default.conf.tmplt.cert"
ls /etc/letsencrypt/cli.ini > 0
if [ $? -ne 0 ]
then
	echo "Basic files are missing, copying initial file."
	cp "/cli.ini" "/etc/letsencrypt/cli.ini" 
fi

ls /etc/letsencrypt/live/${NGINX_SERVER_NAME}/fullchain.pem
if [ $? -ne 0 ]
then
	echo "Certs not present, using template without Certs"
	template_file="default.conf.tmplt"
fi 

envsubst "$( get_env_vars )" < "/conf.d/${template_file}" > "/etc/nginx/conf.d/default.conf"
echo "Vars of /etc/nginx/conf.d/default.conf replaced:"
cat  "/etc/nginx/conf.d/default.conf"
echo ""
service cron start
if [ $template_file = "default.conf.tmplt" ]
then
	echo "Attempting to create certs with letsencrypt"
	nginx
	sleep 1
	./create_cert.sh
	exit_code=$?
	kill -QUIT $( cat /var/run/nginx.pid )
	rm /var/run/nginx.pid
	if [ ${exit_code} -eq 0 ]
	then
		echo "Certificates created successfully, re-launching NGINX"
		./entry_point.sh
	else
		echo "Certificates not created, launching NGINX without them."
	fi
fi
nginx -g "daemon off;"	
