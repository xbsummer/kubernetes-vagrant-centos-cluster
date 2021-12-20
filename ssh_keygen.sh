#!/usr/bin/env bash
echo "begin exec ssh-keygen"
ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa -q
[ -d /vagrant/.ssh ] || mkdir -p /vagrant/.ssh
cat -A ~/.ssh/id_rsa.pub >> /vagrant/.ssh/authorized_keys
echo -e "\n" >> /vagrant/.ssh/authorized_keys 
