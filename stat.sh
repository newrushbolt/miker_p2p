#!/bin/bash

mysql -uroot p2p -e 'select * from worker_counters;'
mysql -uroot p2p -e 'select count(*) as peers from peer_state;'
mysql -uroot p2p -e 'select count(*) as lists from peer_lists;'
mysql -uroot p2p -e 'select count(*) as peer_load_5 from peer_load_5;'
mysql -uroot p2p -e 'select count(*) as peer_bad_30 from peer_bad_30;'
sudo rabbitmqctl list_queues
