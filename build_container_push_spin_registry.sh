#!/bin/bash
#
# Builds the container and pushes it to the nersc registry for SPIN.

echo "This command requires to do 'docker login' before... rember to do it"

nersc_user="crd-dst"
branch=$( git rev-parse --abbrev-ref HEAD )

if [ -z "$NERSC_USER" ]; then
	echo "NERSC_USER is not set, using $nersc_user as registry username."
else
	nersc_user=$NERSC_USER
fi


now=`date "+%Y%m%d-%H%M%S"`
container_name="sciencesearch-nginxv2:$branch-$now"
spin_registry="registry.spin.nersc.gov"
echo "Building container: ${spin_registry}/${nersc_user}/${container_name}"
docker build --no-cache . -t "$container_name"
docker tag ${container_name} ${spin_registry}/${nersc_user}/${container_name}
docker push ${spin_registry}/${nersc_user}/${container_name}