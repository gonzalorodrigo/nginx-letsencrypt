#!/bin/bash

get_env_vars() {
	var_list=$( printenv | cut -d= -f1 )
	for v in $var_list
	do
		echo \$$v
	done
}

replace_conf_file() {
	envsubst "$( get_env_vars )" < "$1" > "/etc/nginx/conf.d/default.conf"
	echo "Vars of /etc/nginx/conf.d/default.conf replaced:"
	cat  "/etc/nginx/conf.d/default.conf"
	echo ""
}

get_resolver() {
	dns_server=$( cat /etc/resolv.conf | grep nameserver | head -1 | cut "-d " -f2 )
	echo $dns_server
}

if [ -z "$NGINX_SERVER_NAME" ]
then
	export NGINX_SERVER_NAME="localhost"
fi

if [ -z "$NGINX_DNS_SERVER" ]
then
	export NGINX_DNS_SERVER=$( get_resolver )
fi

template_file="/conf.d/default.conf.tmplt.cert"
template_file_fallback="/conf.d/default.conf.tmplt.fallback"
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
	template_file="/default.conf.tmplt"
fi 

replace_conf_file "${template_file}"

service cron start
if [ $template_file = "/default.conf.tmplt" ]
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
		replace_conf_file "${template_file_fallback}"
		echo "Certificates not created, launching NGINX without SSL!!"
	fi
fi
nginx -g "daemon off;"	
