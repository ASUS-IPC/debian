#!/bin/bash

images=(lfedge/ekuiper edgexfoundry/app-service-configurable-arm64 redis edgexfoundry/edgex-ui-arm64 edgexfoundry/core-data-arm64 edgexfoundry/support-notifications-arm64 edgexfoundry/core-metadata-arm64 edgexfoundry/core-command-arm64 edgexfoundry/support-scheduler-arm64 hashicorp/consul edgexfoundry/core-common-config-bootstrapper-arm64)

image_tar_gz=(edgexfoundry_ekuiper edgexfoundry_app-service-configurable-arm64 edgexfoundry_redis edgexfoundry_edgex-ui-arm64 edgexfoundry_core-data-arm64 edgexfoundry_support-notifications-arm64 edgexfoundry_core-metadata-arm64 edgexfoundry_core-command-arm64 edgexfoundry_support-scheduler-arm64 edgexfoundry_consul edgexfoundry_bootstrapper)

if ! docker info > /dev/null 2>&1; then
    echo "This script uses docker, and it isn't running - please start docker and try again!"
    exit 1
fi

loop=0

if [ -d "/etc/EdgeX/EdgeXImages" ]; then

    for i in "${images[@]}";
    do
        image=$(docker images | grep $i)

        if [ "$image" = "" ]; then
            echo "Can not find the image $i."
            docker load < /etc/EdgeX/EdgeXImages/${image_tar_gz[$loop]}.tar.gz
            loop=$(($loop +1))
        else
            echo "Delete $image"
            docker rmi -f $(docker images "$i" -a -q)
            docker load < /etc/EdgeX/EdgeXImages/${image_tar_gz[$loop]}.tar.gz
            loop=$(($loop +1))
        fi
    done

    rm -rf /etc/EdgeX/EdgeXImages

else
    echo "Can not find /etc/EdgeX/EdgeXImages"

fi

docker-compose -p edgex -f /etc/EdgeX/docker-compose-no-secty-with-ui-arm64.yml up
