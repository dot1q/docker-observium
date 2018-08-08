#!/bin/bash

sed -i "s/myhostname =.*/myhostname = $(hostname)/" /etc/postfix/main.cf
sed -i "s/mydestination =.*/mydestination = \$myhostname, localhost.localdomain, localhost/" /etc/postfix/main.cf

sed -i "/^myorigin =.*/d" /etc/postfix/main.cf
echo "\$myhostname" > /etc/mailname

#postfix runs in a chroot and needs resolv.conf to resolve hostnames
cp /etc/resolv.conf /var/spool/postfix/etc/resolv.conf

exec /usr/lib/postfix/sbin/master -d -c /etc/postfix