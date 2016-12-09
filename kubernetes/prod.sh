#!/bin/bash
#
# Container startup script  for production.
#
# Scripts to run the baked-in twissandra server
#
#
# Use the common start script to simulate the Docker /etc/hosts hack
#
. twiss-start

export CQLENG_ALLOW_SCHEMA_MANAGEMENT=True

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
        python manage.py benchmark 100 100
    elif [ "$1" = "debug" ]; then
        echo "Running and stall the container for iteractive"
        tail -f /var/log/lastlog
    else
        echo "Unknown args."
        echo ""
        echo "Usage <scriptname> arg"
        echo ""
        echo "   arg:"
        echo "     db - create DB schema is missing, otherwise ignore"
        echo "     er - delete DB schema and data, then create DB schema again"
        echo "     app [ip:host] - run twissandra server at arg or default 0.0.0.0:8222"
        echo "     inj - run random data injector 10 10 0 0" 
        echo "     bench - run fixed size data inject 100 100"
        echo "     debug - stall the container so it is attachable"
        echo ""
    fi
fi    

