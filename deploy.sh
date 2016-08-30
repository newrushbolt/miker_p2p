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
#apt-get install mongodb curl gzip sqlite3 ruby rubygems
#gem install rest-client sqlite3 whois json geoip mongo

###SQLite3 init
sqlite3 peers.sqlite3 <peers.schema

###Mongo init
systemctl start mongo
mongo 127.0.0.1:3303/webrtc mongo_init.js

###download and unpack raw_log
ts=`date +%s`
raw_log_arch="raw_log-$ts.txt.gz"
raw_log_name="raw_log-$ts.txt"
raw_log_link="raw_log"
cd data
curl -o $raw_log_arch http://goodgame.ru/files/lokki7/candy2.txt.gz
gzip -d $raw_log_arch
rm -fr $raw_log_link
ln -s $raw_log_name $raw_log_link
