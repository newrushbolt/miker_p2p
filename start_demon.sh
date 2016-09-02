#!/bin/bash

mkdir log

if [ -f log/.lock ]; then
    echo 'Already running'
else
    ruby raw_peers.demon.rb 1>log/out.log 2>log/error.log&
    touch log/.lock
fi
