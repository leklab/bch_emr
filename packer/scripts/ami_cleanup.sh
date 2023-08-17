#!/bin/bash

shred -u /etc/ssh/*_key /etc/ssh/*_key.pub
rm -rf /root/.ssh/authorized_keys /home/ubuntu/authorized_keys
rm -rf /root/.aws /root/.gradle /root/.local /root/.cache

# Purge logs but retain directory structure
find /var/log -type f -exec rm -v {} \;

apt-get clean
history -c
