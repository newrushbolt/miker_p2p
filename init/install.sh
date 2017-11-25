#!/bin/bash

echo -e "\033[0;31mDon't forget to enable password auth for postgres\033[0m\n"
sudo -u postgres -- psql p2p < p2p.sql
