#!/bin/bash
#
# Container startup script  for development.
#
# This is used to pull the git code when the container runs
# (vs when the container is built.).  This allows quick
# code iterations w/o the need for the docker image
# rebuild.
#
# However, this is not a setup for Production.
# The code/app/whatever should be built into the
# container image. 
#
#make sure ssh is ok
eval "$(ssh-agent -s)"
ssh-add /root/.ssh/docker_rsa
ssh-add -l

ssh -v -T -F /root/.ssh/config git@github.com

#
# pull the git repo so we don't have to rebake this image
#
git clone git@github.com:mikeln/twissandra.git /twissandra

#
# Use the common start script to simulate the Docker /etc/hosts hack
#
. twiss-start

# Get pip to download and install requirements:
pip install -r /twissandra/requirements.txt

cd /twissandra

if [ $# -lt 1 ]; then
   #python manage.py 
   #
   # change the default run to server
   #
   echo "running django server on 8222"
   python manage.py runserver 0.0.0.0:8222
else
    if [ "$1" = "db" ]; then
        echo "Create the DB schema if not present."
        python manage.py sync_cassandra
    elif [ "$1" = "er" ]; then
        echo "Create the DB.  Delete/Erase the schema first if present."
        python manage.py sync_cassandra y
    elif [ "$1" = "app" ]; then
        echo "Starting the Server"
        if [ -n "$2" ]; then
            echo "Running server at $2"
            python manage.py runserver $2
        else
            echo "Running server at default 0.0.0.0:8222"
            python manage.py runserver 0.0.0.0:8222
        fi
    elif [ "$1" = "inj" ]; then
        echo "Running the random data injection"
        python manage.py inject_data 10 10 0 0
    elif [ "$1" = "bench" ]; then
        echo "Running the benchmark data injection"
        python manage.py bench 100 100
    elif [ "$1" = "debug" ]; then
        echo "Stalling the container for iteractive shell"
        tail -f /var/log/lastlog
    else
        echo "Unknown args."
    fi
fi    
