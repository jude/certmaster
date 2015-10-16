#!/bin/bash

/etc/init.d/certmaster stop
rpm -e certmaster
rpm -i /root/certmaster.git/rpm-build/certmaster-0.28-1pwan.noarch.rpm
cp /etc/certmaster/certmaster.conf.rpmsave /etc/certmaster/certmaster.conf
cp /etc/certmaster/minion.conf.rpmsave /etc/certmaster/minion.conf
cd tests
./test-certmaster.sh

