#!/usr/bin/env bash

DOCKER_NAME=${DOCKER_NAME:-gp-okta}

container=$(docker ps -q -f name=${DOCKER_NAME})
if [ -z "${container}" ]; then
    echo "VPN is not running!"
    exit 1
fi

# Watch output for close-down output
( timeout 30 docker logs -f --since 0s ${DOCKER_NAME} & )

docker stop ${DOCKER_NAME} > /dev/null

echo
echo
echo "VPN stopped."
