#!/bin/bash

get_env_vars() {
	var_list=$( printenv | cut -d= -f1 )
	for v in $var_list
	do
		echo \$$v
	done
}

v_l=$( get_vars )

echo $v_l
