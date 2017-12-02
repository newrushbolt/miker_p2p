#!/bin/bash

psql p2p -h 127.0.0.1 -p 5432 -Up2p -W -c "select genereate_peer_list('connid1','channel1','10');"
