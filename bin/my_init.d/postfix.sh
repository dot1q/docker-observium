#!/bin/bash


if ! [ "${MAIL_RELAY_HOST}" = "" ]; then
    sed -i "s/relayhost =.*/relayhost = ${MAIL_RELAY_HOST}/" /etc/postfix/main.cf
fi
if ! [ "${MAIL_INET_PROTOCOLS}" = "" ]; then 
    sed -i "s/inet_protocols =.*/inet_protocols = ${MAIL_INET_PROTOCOLS}/" /etc/postfix/main.cf
fi
sed -i "s/myhostname =.*/myhostname = $(hostname)/" /etc/postfix/main.cf
sed -i "s/mydestination =.*/mydestination = ${NAGIOS_FQDN}, \$myhostname, localhost.localdomain, localhost/" /etc/postfix/main.cf

sed -i "/^myorigin =.*/d" /etc/postfix/main.cf
echo "${NAGIOS_FQDN}" > /etc/mailname

#postfix runs in a chroot and needs resolv.conf to resolve hostnames
cp /etc/resolv.conf /var/spool/postfix/etc/resolv.conf

exec /usr/lib/postfix/sbin/master -d -c /etc/postfix