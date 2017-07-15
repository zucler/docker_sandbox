#!/bin/bash
PATH=/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/sbin:/bin:

/usr/sbin/sshd -D

while true
do
    sleep 60
done