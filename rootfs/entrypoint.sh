#!/bin/bash

set -e

# if command starts with an option, prepend supervisord
if [ "${1:0:1}" = '-' ]; then
	set -- supervisord "$@"
fi

if [ "$1" = 'supervisord' ]; then
    if [ ! -e /seafile/ccnet/docker_version ] || [ ! -e /seafile/conf/docker_version ]; then
        
        cd /seafile/seafile-server-${SEAFILE_VERSION}
        echo "-> Seafile is not configured yet. Running setup script now."
        
        ./setup-seafile-mysql.sh
        mv /seafile/ccnet-setup/* /seafile/ccnet
        mv /seafile/conf-setup/* /seafile/conf
        echo "${SEAFILE_VERSION}" > /seafile/conf/docker_version
        
        echo "-> Seafile is configured now. However, you will need to start it manually one time to configure the administrator account."
        echo "-> Dropping you to a shell"
        set -- bash
    else
        echo "-> Seafile is already configured."
        export SEAFILE_DOCKER=`cat /seafile/conf/docker_version`
        if [ ! $SEAFILE_VERSION ==  $SEAFILE_DOCKER ]; then
            echo "-> Seafile version in docker_version file does not match version which is about to be run."
            echo "-> Configured version: ${SEAFILE_DOCKER}"
            echo "-> Version about to be run: ${SEAFILE_VERSION}"
            echo "-> Dropping you to a shell so you can upgrade as neccessary."
            echo "-> Use 'seafile-updated' to update the configured version to the current one"
            read -p "-> Press [ENTER] to continue"
            set -- bash
        else
            echo "-> No update neccessary, start Seafile services"
        fi;
    fi;
fi;

echo "-> Fixing permissions (this can take a while)..."
chown -R www-data:www-data /seafile

echo "-> Starting $@"
exec "$@"
