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
# hardcode the cass for now
#echo "10.247.81.229 cass" >> /etc/hosts
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

# Get pip to download and install requirements:
pip install -r /twissandra/requirements.txt

cd /twissandra

if [ $# -lt 1 ]; then
   python manage.py 
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
