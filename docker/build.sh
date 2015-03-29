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
echo "10.247.87.50 cass" >> /etc/hosts

# Get pip to download and install requirements:
pip install -r /twissandra/requirements.txt

cd /twissandra

python manage.py runserver

tail -f /var/log/lastlog
