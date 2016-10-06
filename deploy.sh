#!/bin/bash

#yum install curl gzip sqlite3 mongodb-server mongodb-client ruby rubygems
# rubygem-rest-client rubygem-sqlite3 rubygem-whois rubygem-json rubygem-geoip rubygem-mongo

command curl -sSL https://rvm.io/mpapis.asc | gpg --import -
curl -sSL https://get.rvm.io | bash -s stable

#source /etc/profile.d/rvm.sh
#rvm install ruby-2.2
#rvm --default use 2.2

gem install rest-client mysql2 whois json geoip bunny logger sinatra thin ruby-prof --no-ri --no-doc
mkdir -p var/www
mkdir -p var/log
mkdir -p var/run
mkdir -p init

###MySQL init
service mariadb restart
mysql -uroot -pwb5nv6d8< p2p.sql

