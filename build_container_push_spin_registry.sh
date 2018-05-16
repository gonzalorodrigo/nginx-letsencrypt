#!/bin/bash
#
# Builds the container and pushes it to the nersc registry for SPIN.

echo "This command requires to do 'docker login' before... rember to do it"
echo "Also, if you want NGINX to run with a particular UID and GID run"\
"./build_container_push_spin_registry.sh (uid_number) (gid_number)"

nersc_user="crd-dst"
branch=$( git rev-parse --abbrev-ref HEAD )

if [ -z "$NERSC_USER" ]; then
	echo "NERSC_USER is not set, using $nersc_user as registry username."
else
	nersc_user=$NERSC_USER
fi
build_args=""
if [ "$#" -ge 1 ]; then
    build_args="--build-arg SPIN_UID=$1"
fi

if [ "$#" -ge 2 ]; then
    build_args="${build_args} --build-arg SPIN_GID=$2"
fi

echo "Build Args: ${build_args}"

now=`date "+%Y%m%d-%H%M%S"`
container_name="sciencesearch-nginxv2:$branch-$now"
spin_registry="registry.spin.nersc.gov"
docker build --no-cache . -t "$container_name" ${build_args}
docker tag ${container_name} ${spin_registry}/${nersc_user}/${container_name}
docker push ${spin_registry}/${nersc_user}/${container_name}