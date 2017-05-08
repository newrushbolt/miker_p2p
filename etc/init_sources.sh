#!/bin/bash

rvm_bin_path='/usr/local/rvm/bin'
GEM_HOME='/usr/local/rvm/gems/ruby-2.2.4'
IRBRC='/usr/local/rvm/rubies/ruby-2.2.4/.irbrc'
MY_RUBY_HOME='/usr/local/rvm/rubies/ruby-2.2.4'
rvm_path='/usr/local/rvm'
rvm_prefix='/usr/local'
PATH='/usr/local/rvm/gems/ruby-2.2.4/bin:/usr/local/rvm/gems/ruby-2.2.4@global/bin:/usr/local/rvm/rubies/ruby-2.2.4/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/rvm/bin'
rvm_version='1.27.0 (latest)'
GEM_PATH='/usr/local/rvm/gems/ruby-2.2.4:/usr/local/rvm/gems/ruby-2.2.4@global'
RUBY_VERSION='ruby-2.2.4'

USER='mihailov.s'

COMMON_ONLINE_PEERS_WORKERS=2
PEER_LIST_MASTER_WORKERS=1
PEER_LIST_SLAVE_WORKERS=2
PEER_LOG_WORKERS=8
OFFLINE_PEERS_WORKERS=1
SLOW_ONLINE_PEERS_WORKERS=1

ruby /home/mihailov.s/miker_p2p/etc/zabbix.rb
