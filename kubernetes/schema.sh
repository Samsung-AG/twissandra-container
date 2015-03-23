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
echo "Twissandra Schema script start"
#URDIR="${BASH_SOURCE%/*}"
#if [[ ! -d "$CURDIR" ]]; then CURDIR="$PWD"; fi
#. "$CURDIR/twiss-start"
#. "$CURDIR/init.sh"
. twiss-start

# Start the app
# NOTE: need to supply the args for this...
echo Starting Twissandra Schema...
#
# pass the input args to the python thing...will NOT erase when the choice is given due to no iteractive terminal
#
python /twissandra/manage.py sync_cassandra
# lockup the container..
#tail -f /var/log/lastlog
