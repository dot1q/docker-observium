# == Observium
#
# Provide the following environment variables to source Observium from your
# Professional Edition subscription instead of the Community Edition upstream:
#
#   USE_SVN=true
#   SVN_USER=username
#   SVN_PASS=password
#   SVN_REPO=http://url/to/repo@rev
#
# If you don't have a subscription but run your own managed repository,
# SVN_REPO is arbritrarily accepted. If USE_SVN is specified, credentials and
# repository information must also be otherwise will fallback to community
# version.
#
# The following volumes may be used with their descriptions next to them:
#
#   /config                     : Should contain your `config.php`, otherwise
#                                 default will be used
#   /opt/observium/html         : Provided to ease adding plugis (weathermap!)
#   /opt/observium/logs         : Would be nice to store these somewhere
#                                 non-volatile!
#   /opt/observium/rrd          : Will consume the most storage.
#   /var/run/mysqld/mysqld.sock : If your MySQL server is on the same host that
#                                 serves the container, setting 'localhost' in
#                                 observium config will look for the unix
#                                 socket instead of using TCP.
#
#
FROM phusion/baseimage:0.11
EXPOSE 8000/tcp
VOLUME ["/config", \
        "/opt/observium/", \
        "/var/run/mysqld/mysqld.sock"]

# === phusion/baseimage pre-work
CMD ["/sbin/my_init"]

# === General System

# yelp/observium env mostly for reference
ENV WORKERS 4
ENV WEATHERMAP false
ENV CUSTOM_PHP_INI false
ENV HOUSEKEEPING_ARGS '-yet'
ENV USE_SVN false
ENV SVN_USER ''
ENV SVN_PASS ''
ENV SVN_REPO ''
ENV FQDN 'observium.example.com'

# Avoid any interactive prompting
ENV DEBIAN_FRONTEND noninteractive

# Language specifics
ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8 

# Install Observium prereqs
RUN apt-add-repository universe && apt-add-repository multiverse
RUN apt-get update -q && \
    apt-get install -y --no-install-recommends \
      apache2 \
      at \
      fping \
      git \
      graphviz \
      graphviz \
      imagemagick \
      ipmitool \
      libapache2-mod-php7.2 \
      libvirt-bin \
      mariadb-client \
      mtr-tiny \
      nmap \
      php7.2-cli \
      php7.2-gd \
      php7.2-json \
      php7.2-ldap \
      php7.2-mysqli \
      php7.2-snmp \
      php-pear \
      pwgen \
      python-mysqldb \
      sendmail \
      rancid \
      rrdcached \
      rrdtool \
      snmp \
      software-properties-common \
      subversion \
      telnet \
      unzip \
      wget \
      whois

RUN mkdir -p \
        /config \
        /opt/observium/html \
        /opt/observium/logs \
        /opt/observium/rrd

# === Webserver - Apache + PHP7
COPY conf/rancid.conf /etc/rancid/rancid.conf
RUN useradd -ms /bin/bash rancid
USER rancid
RUN /var/lib/rancid/bin/rancid-cvs

# Symoblic link for .cloginrc in the root home dir
RUN ln -s /var/lib/rancid/.cloginrc /root/
USER root

RUN a2dismod mpm_event && \
    a2enmod mpm_prefork && \
    a2enmod php7.2 && \
    a2enmod rewrite

RUN mkdir /etc/service/apache2
RUN adduser rancid --disabled-password --system --shell /bin/bash --group
RUN chown rancid:rancid -R /var/lib/rancid
COPY bin/service/apache2.sh /etc/service/apache2/run
RUN chmod +x /etc/service/apache2/run

# Boot-time init scripts for phusion/baseimage
COPY bin/my_init.d /etc/my_init.d/
RUN chmod +x /etc/my_init.d/* && \
    chown -R nobody:users /opt/observium && \
    chown -R nobody:users /config && \
    chmod 755 -R /opt/observium && \
    chmod 755 -R /config

# Configure apache2 to serve Observium app
COPY ["conf/apache2.conf", "conf/ports.conf", "/etc/apache2/"]
COPY conf/apache-observium /etc/apache2/sites-available/000-default.conf
COPY conf/rrdcached /etc/default/rrdcached
RUN rm /etc/apache2/sites-available/default-ssl.conf && \
    echo www-data > /etc/container_environment/APACHE_RUN_USER && \
    echo www-data > /etc/container_environment/APACHE_RUN_GROUP && \
    echo /var/log/apache2 > /etc/container_environment/APACHE_LOG_DIR && \
    echo /var/lock/apache2 > /etc/container_environment/APACHE_LOCK_DIR && \
    echo /var/run/apache2.pid > /etc/container_environment/APACHE_PID_FILE && \
    echo /var/run/apache2 > /etc/container_environment/APACHE_RUN_DIR && \
    chown -R www-data:www-data /var/log/apache2 && \
    usermod -a -G root www-data
    #rm -Rf /var/www && \
    #ln -s /opt/observium/html /var/www
# === Cron and finishing
COPY cron.d /etc/cron.d/

# === phusion/baseimage post-work
# Clean up APT when done
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*