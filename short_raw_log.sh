#!/bin/bash

cnt=$1
echo '{"Logs":[' > data/raw_log_$cnt
head data/raw_log -n $cnt >>data/raw_log_$cnt
sed -i 's/\}$/},/' data/raw_log_$cnt
sed -i '$ s/.$//g' data/raw_log_$cnt
echo ']}' >> data/raw_log_$cnt
