#!/bin/bash

### BEGIN INIT INFO
# Provides:          make_peer_list
# Required-Start:    $local_fs $remote_fs $network $syslog $nginx $mysql $mongodb
# Required-Stop:     $local_fs $remote_fs $network $syslog $nginx $mysql $mongodb
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Starts P2P make_peer_list HTTP workers
# Description:       Starts P2P make_peer_list HTTP workers
### END INIT INFO

rvm_bin_path='/usr/local/rvm/bin'
GEM_HOME='/usr/local/rvm/gems/ruby-2.2.4'
IRBRC='/usr/local/rvm/rubies/ruby-2.2.4/.irbrc'
MY_RUBY_HOME='/usr/local/rvm/rubies/ruby-2.2.4'
rvm_path='/usr/local/rvm'
rvm_prefix='/usr/local'
PATH='/usr/local/rvm/gems/ruby-2.2.4/bin:/usr/local/rvm/gems/ruby-2.2.4@global/bin:/usr/local/rvm/rubies/ruby-2.2.4/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/rvm/bin'
rvm_version='1.27.0 (latest)'
GEM_PATH='/usr/local/rvm/gems/ruby-2.2.4:/usr/local/rvm/gems/ruby-2.2.4@global'
RUBY_VERSION='ruby-2.2.4'


NAME='make_peer_list'
WORKER='make_peer_list.demon.rb'
USER='mihailov.s'
APPDIR='/home/mihailov.s/miker_p2p'
WORKERS=2

cd $APPDIR

start() {
    for (( i = 1; i <= $WORKERS; i++ ))
    do
        PID_FILE=$APPDIR/var/run/"$NAME"_"$i".pid
	echo $PID_FILE
	if [ ! -f "$PID_FILE" ] ; then
            ruby "$APPDIR/$WORKER" "350$i" >> "$APPDIR"/var/log/"$NAME"_"$i".service.log 2>&1 &
	    PID=`echo $!`
	    echo $PID > $PID_FILE
	    echo -e "\033[36m $NAME worker $i \033[0m\t Started, PID $PID"
	else
	    PID=`cat $PID_FILE`
	    if [ "`ps --pid $PID`" ] ; then
	        echo  -e "\033[36m $NAME worker $i \033[0m\t Already running, PID $PID"
	    else
	        echo  -e "\033[36m $NAME worker $i \033[0m\t Not running, but PID file $PID_FILE exists"
	    fi
	fi
    done
}

stop() {
    for (( i = 1; i <= $WORKERS; i++ ))
    do
        PID_FILE=$APPDIR/var/run/"$NAME"_"$i".pid
        echo $PID_FILE
        if [ -f "$PID_FILE" ] ; then
          PID=`cat $PID_FILE`
          if [ "`ps --pid $PID`" ] ; then
            echo -e "\033[36m $NAME worker $i \033[0m\t Killing $PID process"
            kill -TERM $PID
          else
            echo -e "\033[36m $NAME worker $i \033[0m\t Process $PID is not running"
          fi
          rm $PID_FILE
        else
          echo -e "\033[36m $NAME worker $i \033[0m\t No PID file $PID_FILE exists"
        fi
    done
}

status() {
    for (( i = 1; i <= $WORKERS; i++ ))
    do
        PID_FILE=$APPDIR/var/run/"$NAME"_"$i".pid
        if [ -f "$PID_FILE" ] ; then
	  PID=`cat $PID_FILE`
          if [ "`ps --pid $PID`" ] ; then
	    echo -e "\033[36m $NAME worker $i \033[0m\t Running, PID $PID"
          else
            echo -e "\033[36m $NAME worker $i \033[0m\t PID file $PID_FILE exists, but service is not running"
          fi
        else
          echo -e "\033[36m $NAME worker $i \033[0m\t Not Running"
        fi
    done
}

case "$1" in
  start)
    start
    ;;

  stop)
    stop
    ;;

  restart)
    stop
    start
    ;;

  status)
    status
    ;;

  *)
    echo 'use start or stop'
    ;;
esac
