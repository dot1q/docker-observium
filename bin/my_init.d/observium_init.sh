#!/bin/bash

# == Fetch proper Observium version

professional_svn() {
    if [ -d /opt/observium/.svn ] ;
    then
        cd /opt/observium &&
        svn up --non-interactive \
            --username $SVN_USER \
            --password $SVN_PASS

        /opt/observium/discovery.php -u
    else 
        cd /tmp &&
        svn co --non-interactive \
            --username $SVN_USER \
            --password $SVN_PASS \
            $SVN_REPO observium
        cp -r /tmp/observium/* /opt/observium/ && rm -rf /tmp/observium
        /opt/observium/discovery.php -u
    fi
}

if [[ "$USE_SVN" == "true" && "$SVN_USER" && "$SVN_PASS" && "$SVN_REPO" ]]
then
    professional_svn
else
    echo "Must use professional edition"
fi

# == Configuration section

# Queue jobs for later execution while configuration is being sorted out
atd

# Check for `config.php`. If it doesn't exist, use `config.php.default`,
# substituting SQL credentials with observium/"random".
if [ -f /config/config.php ]; then
  echo "Using existing PHP database config file."
  echo "/opt/observium/discovery.php -u" | at -M now + 1 minute
else
  echo "Loading PHP config from default."
  mkdir -p /config/databases
  cp /opt/observium/config.php.default /config/config.php
  chown nobody:users /config/config.php
  PW=$(date | sha256sum | cut -b -31)
  sed -i -e 's/PASSWORD/'$PW'/g' /config/config.php
  sed -i -e 's/USERNAME/observium/g' /config/config.php
  echo "/opt/observium/discovery.php -u" | at -M now + 1 minute
fi

ln -s /config/config.php /opt/observium/config.php

# CHECK: Should we do this twice? It's done in Dockerfile and here. It's done
# here to recursively fix permissions of config.php and could be left here and
# taken out of Dockerfile unless anyone thinks it hurts the Dockerfile
# readability.
chown nobody:users -R /opt/observium
chmod 755 -R /opt/observium
