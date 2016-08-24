#!/bin/bash

###PEERS.SQLITE#
sqlite3 peers.sqlite3 <peers.schema

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
