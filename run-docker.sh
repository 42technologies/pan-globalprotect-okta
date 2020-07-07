#!/usr/bin/env bash

DOCKER_IMAGE=${DOCKER_IMAGE:-gp-okta}
DOCKER_TAG=${DOCKER_TAG:-latest}
DOCKER_NAME=${DOCKER_NAME:-gp-okta}

CONFIG=${CONFIG:-$1}
CONFIG=${CONFIG:-gp-okta.conf}

conf_username=$(grep "^username" ${CONFIG} | awk -F \= '{print $2}' | tr -d " ")
conf_password=$(grep "^password" ${CONFIG} | awk -F \= '{print $2}' | tr -d " ")

### detect where username is filled in
if [[ "${conf_username}" ]]; then
    GP_USERNAME=${conf_username}
fi

if [[ -z "${conf_username}" && -z "${GP_USERNAME}" ]]; then
    read -p "Enter Okta username: " GP_USERNAME
fi

### detect where password is filled in
if [[ "${conf_password}" ]]; then
    GP_PASSWORD=${conf_password}
fi

if [[ -z "${conf_password}" && -z "${GP_PASSWORD}" ]]; then
    read -s -p "Enter Okta password: " GP_PASSWORD
    echo
fi

# If no TOTP secrets are specified, prompt for OTP.
totp_secrets=$(grep "^totp." ${CONFIG} | awk -F \= '{print $2}' | tr -d " ")
if [[ -z "${totp_secrets}" ]]; then
    read -p "Enter MFA OTP code: " totp
fi

echo

docker run \
    -d \
    --name=${DOCKER_NAME} \
    --rm \
    --privileged \
    --net=host \
    --cap-add=NET_ADMIN \
    --device /dev/net/tun \
    -e GP_USERNAME=${GP_USERNAME} \
    -e GP_PASSWORD=${GP_PASSWORD} \
    -e GP_TOTP_CODE=${totp} \
    -e GP_EXECUTE=1 \
    -e GP_OPENCONNECT_CMD=/usr/local/sbin/openconnect \
    -v /etc/resolv.conf:/etc/resolv.conf \
    -v $(readlink -f ${CONFIG}):/etc/gp-okta.conf \
    ${DOCKER_IMAGE}:${DOCKER_TAG} \
    > /dev/null

# Watch output for successful, for a little while at least
( timeout 30 docker logs -f ${DOCKER_NAME} & ) | sed '/Connected as/q'

# If container is gone, something went awry
echo
echo
if [ -z "$(docker ps -q -f name=${DOCKER_NAME})" ]; then
    echo
    echo
    echo "VPN failed to start!"
    exit 1
else
    echo "VPN running"
    exit 0
fi
