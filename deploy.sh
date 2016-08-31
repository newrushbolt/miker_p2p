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
gem install rest-client mysql2 whois json geoip mongo logger

###MySQL init
mysql -uroot -pwb5nv6d8 p2p < p2p.sql
###Mongo init
service start mongo
mongo 127.0.0.1:3303/webrtc mongo_init.js
