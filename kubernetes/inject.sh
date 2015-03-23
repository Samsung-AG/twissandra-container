#!/usr/bin/env bash
#
# Twissandra inject data command
# 3/13/2015 mikeln
#
# This attempts to determine if we are starting in Kubernetes or not.
# If so, read the needed Kubernetes env vars and store the information in /etc/hosts
# if not, assume we are running in docker only...do the docker only setup (nothing in this case) 
#
# any app just needs to locate the cassandra kubernetes service entrypoint
#
echo "Twissandra inject script start"

#URDIR="${BASH_SOURCE%/*}"
#if [[ ! -d "$CURDIR" ]]; then CURDIR="$PWD"; fi
#. "$CURDIR/twiss-start"
#. "$CURDIR/init.sh"
. twiss-start

# Start the app
# NOTE: need to supply the args for this...
echo Starting Twissandra inject...
#
# pass the input args to the python thing...
#
python /twissandra/manage.py inject_data 10 10 0 0
