#!/bin/bash

mkdir log

if [ -f log/.lock ]; then
    echo 'Already running'
else
    ruby raw_peers.demon.rb&
    touch log/.lock
fi
