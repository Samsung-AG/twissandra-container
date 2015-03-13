#!/usr/bin/env bash
#
# Twissandra schema command
# 3/13/2015 mikeln
#
# This attempts to determine if we are starting in Kubernetes or not.
# If so, read the needed Kubernetes env vars and store the information in /etc/hosts
# if not, assume we are running in docker only...do the docker only setup (nothing in this case) 
#
# any app just needs to locate the cassandra kubernetes service entrypoint
#
INKUB=`env | grep ^KUBERNETES`
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
        #
        # simulate DOCKER by adding to /etc/hosts file
        #
        echo "$CASSIP $CASSHOSTNAME" >> /etc/hosts
    else
        echo "WARNING no cassandra kubernetes service info was found.  Is it running?"
        exit 1 
    fi
else
    echo "Running inside Docker only...nothing to do"
fi
# Start the app
# NOTE: need to supply the args for this...
echo Starting Twissandra Schema...
#
# pass the input args to the python thing...
#
python /twissandra/manage.py sync_cassandra
