#!/bin/bash

echo "*** Setting postfix vars..."
sed -i "s/myhostname =.*/myhostname = $(hostname)/" /etc/postfix/main.cf
sed -i "s/mydestination =.*/mydestination = \$myhostname, localhost.localdomain, localhost/" /etc/postfix/main.cf

sed -i "/^myorigin =.*/d" /etc/postfix/main.cf
echo "\$myhostname" > /etc/mailname

#postfix runs in a chroot and needs resolv.conf to resolve hostnames
echo "*** Copying files for resolv.conf..."
cp /etc/resolv.conf /var/spool/postfix/etc/resolv.conf
echo "*** Something something, postfix?..."
/usr/lib/postfix/sbin/master -d -c /etc/postfix