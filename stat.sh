#!/bin/bash

mysql -uroot p2p -e 'select * from worker_counters;'
mysql -uroot p2p -e 'select count(*) as peers from peer_state;'
mysql -uroot p2p -e 'select count(*) as lists from peer_lists;'
sudo rabbitmqctl list_queues
