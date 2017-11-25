#!/bin/bash

sudo -u postgres -- psql p2p < gen.sql
sudo -u postgres -- psql p2p < test_data.sql
sudo -u postgres -- psql p2p -c "select genereate_peer_list('connid1','channel1');"
