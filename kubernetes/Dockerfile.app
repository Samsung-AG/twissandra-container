############################################################
# Dockerfile to build Python WSGI Application Containers
# Based on Ubuntu
############################################################

# Set the base image to Ubuntu
FROM ubuntu

# File Author / Maintainer
MAINTAINER Mikel Nelson <mikel.n@samsung.com>

# Add the application resources URL
RUN echo "deb http://archive.ubuntu.com/ubuntu/ $(lsb_release -sc) main universe" >> /etc/apt/sources.list

# Update the sources list
RUN apt-get update

# Install basic applications
RUN apt-get install -y tar git curl nano wget dialog net-tools build-essential

# additions that seem to be needed now
RUN apt-get install -y libev4 libev-dev

# Install Python and Basic Python Tools
RUN apt-get install -y python python-dev python-distribute python-pip

# use github for our development /twissandra instead of baking in
#
# add ssh key for github
#
# ssh/ is prepopulated the docker_rsa.pub key must be in github account first!
#
ADD /ssh /root/.ssh
RUN chmod 700 /root/.ssh
RUN chmod 600 /root/.ssh/*
# get key of destination ...
RUN ssh-keyscan github.com >> /root/.ssh/known_hosts
#
# add container startup script
#
ADD init.sh /usr/local/bin/twiss-start
RUN chmod 755 /usr/local/bin/twiss-start

ADD schema.sh /usr/local/bin/twiss-schema
RUN chmod 755 /usr/local/bin/twiss-schema

ADD inject.sh /usr/local/bin/twiss-inject
RUN chmod 755 /usr/local/bin/twiss-inject

ADD web.sh /usr/local/bin/twiss-web
RUN chmod 755 /usr/local/bin/twiss-web

ADD benchmark.sh /usr/local/bin/twiss-bench
RUN chmod 755 /usr/local/bin/twiss-bench

# Expose ports
EXPOSE 8222
#
USER root
CMD [ "twiss-web" ]
