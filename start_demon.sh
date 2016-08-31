#!/bin/bash

mkdir log

if [ -f log/demon.lock ]; then
    echo 'Already running'
else
    ruby raw_peers.demon.rb&
    touch log/demon.lock
fi
