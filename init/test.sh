#!/bin/bash

sudo -u postgres -- psql < gen.sql
sudo -u postgres -- psql < test_data.sql
sudo -u postgres -- psql -c "select genereate_peer_list('connid1','channel1');"
