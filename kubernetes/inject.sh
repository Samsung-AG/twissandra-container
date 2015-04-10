#!/bin/bash

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
   # change the default to 10 10 inject
   #
   echo "running inject_data"
   python manage.py inject_data 10 10 0 0
else
    if [ "$1" = "db" ]; then
        echo "do db thing"
        python manage.py sync_cassandra
    elif [ "$1" = "er" ]; then
        echo "erase thing"
        python manage.py sync_cassandra y
    elif [ "$1" = "app" ]; then
        echo "server thing"
        if [ -n "$2" ]; then
            echo "running server at $2"
            python manage.py runserver $2
        else
            echo "running server at default 0.0.0.0:8222"
            python manage.py runserver 0.0.0.0:8222
        fi
    elif [ "$1" = "inj" ]; then
        echo "script inject thing"
        python manage.py inject_data 10 10 0 0
    else
        echo "unknown args"
    fi
fi    


#tail -f /var/log/lastlog
