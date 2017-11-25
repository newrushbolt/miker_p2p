#!/bin/bash

psql < gen.sql
psql < test_data.sql
psql -c "select genereate_peer_list('connid1','channel1');"
