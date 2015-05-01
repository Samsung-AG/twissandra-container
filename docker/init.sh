#!/usr/bin/env bash
#
# Twissandra Container App Startup Script
# 3/11/2015 mikeln
#
# This attempts to determine if we are starting in Kubernetes or not.
# If so, read the needed Kubernetes env vars and store the information in /etc/hosts
# if not, assume we are running in docker only...do the docker only setup (nothing in this case) 
#
# any app just needs to locate the cassandra kubernetes service entrypoint
#
# Use this as a common script 
#
# Use KUBERNETES_RO vs just KUBERNETES as we may have set some needed stuff in our env
# whether or not we are acutally running kubernetes.  KUBERNETES_RO_* should only be 
# set by Kubernetes
#
INKUB=`env | grep ^KUBERNETES_RO`
if [ -n "$INKUB" ]; then
    # in kubernetes
    echo "Running inside Kubernetes"
    #
    # note: this is the expect hostname in the app: cass
    #
    CASSHOSTNAME="cass"
    #
    # find the cassandra service: we only need the host IP... ports are a given 9042, 9160
    #
    CASSIP=`env | grep CASSANDRA_SERVICE_HOST | cut -d "=" -f 2`
    if [ -n "$CASSIP" ]; then
        echo "Found Cassandra Service at IP: $CASSIP"
        #
        # simulate DOCKER by adding to /etc/hosts file
        #
        echo "$CASSIP $CASSHOSTNAME" >> /etc/hosts
        #
        # modify the python file directly (the /etc/hosts hack does not appear to work consistently)
        #  
#        sed -i -e "s/'cass'/'$CASSIP'/" /twissandra/cass.py
        #
        # inconsistent in code...hence the second location
#        sed -i -e "s/'cass'/'$CASSIP'/" /twissandra/tweets/management/commands/sync_cassandra.py
        #
        # here is the real config
#        sed -i -e "s/'cass'/'$CASSIP'/" /twissandra/settings.py
        echo "hosts change ------------------"
        cat /etc/hosts
        echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
    else
        echo "WARNING no cassandra kubernetes service info was found.  Is it running?"
#        exit 1
    fi
else
    echo "Running inside Docker only...nothing to do"
fi

