#!/bin/bash

# we'll need software
# curl
# gzip
# sqlite3
# mongodb-server
# mongodb-client
# ruby
# rubygems
# rubygem-rest-client
# rubygem-sqlite3
# rubygem-whois
# rubygem-json
# rubygem-geoip
# rubygem-mongo

#yum install curl gzip sqlite3 mongodb-server mongodb-client ruby rubygems
# rubygem-rest-client rubygem-sqlite3 rubygem-whois rubygem-json rubygem-geoip rubygem-mongo

#Debian block
#apt-get update
apt-get install mongodb curl gzip sqlite3 mysql-server mysql-client libmysqlclient-dev
command curl -sSL https://rvm.io/mpapis.asc | gpg --import -
curl -sSL https://get.rvm.io | bash -s stable

#source /etc/profile.d/rvm.sh
#rvm install ruby-2.2
#rvm --default use 2.2

gem install rest-client mysql2 whois json geoip mongo logger sinatra thin benchmark
mkdir -p var/www
mkdir -p var/log
mkdir -p var/run

###MySQL init
service mysql restart
mysql -uroot -pwb5nv6d8< p2p.sql
###Mongo init
#sed shit to set port=3303
service restart mongo
mongo 127.0.0.1:3303/webrtc mongo_init.js
