#!/bin/bash

mysql -uroot p2p -e 'truncate table worker_counters;'
mysql -uroot p2p -e 'truncate table peer_state;'
mysql -uroot p2p -e 'truncate table peer_lists;'
ruby rabbit_delete.rb
