#!/bin/bash

mkdir log

if [ -f log/server.lock ]; then
    echo 'Already running'
else
    ruby server.rb >>log/web.log 2>>log/web.log&
    touch log/server.lock
fi
