#!/bin/bash

### BEGIN INIT INFO
# Provides:          peer_list_worker
# Required-Start:    $local_fs $remote_fs $network $syslog $nginx $mysql $rabbitmq
# Required-Stop:     $local_fs $remote_fs $network $syslog $nginx $mysql $rabbitmq
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Starts P2P peer_list_worker
# Description:       Starts P2P peer_list_worker
### END INIT INFO

NAME='peer_list_slave'
WORKER='peer_list_slave.worker.rb'
APPDIR='/home/mihailov.s/miker_p2p'
source $APPDIR/etc/init_sources.sh

cd $APPDIR
#ruby zabbix.rb $WORKERS >zabbix.json

start() {
    for (( i = 1; i <= $PEER_LIST_SLAVE_WORKERS; i++ ))
    do
        PID_FILE=$APPDIR/var/run/"$NAME"_"$i".pid
	if [ ! -f "$PID_FILE" ] ; then
            ruby "$APPDIR/$WORKER" "$i" >> "$APPDIR"/var/log/"$NAME"_"$i".service.log 2>&1 &
	    PID=`echo $!`
	    echo $PID > $PID_FILE
	    echo -e "\033[36m $NAME worker $i \033[0m\t Started, PID $PID"
	else
	    PID=`cat $PID_FILE`
	    if [ `ps --pid $PID >/dev/null 2>/dev/null;echo $?` -eq 0 ] ; then
	        echo  -e "\033[36m $NAME worker $i \033[0m\t Already running, PID $PID"
	    else
	        echo  -e "\033[36m $NAME worker $i \033[0m\t Not running, but PID file $PID_FILE exists"
	    fi
	fi
    done
}

stop() {
    for (( i = 1; i <= $PEER_LIST_SLAVE_WORKERS; i++ ))
    do
        PID_FILE=$APPDIR/var/run/"$NAME"_"$i".pid
        if [ -f "$PID_FILE" ] ; then
          PID=`cat $PID_FILE`
          if [ `ps --pid $PID >/dev/null 2>/dev/null;echo $?` -eq 0 ] ; then
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
    for (( i = 1; i <= $PEER_LIST_SLAVE_WORKERS; i++ ))
    do
        PID_FILE=$APPDIR/var/run/"$NAME"_"$i".pid
        if [ -f "$PID_FILE" ] ; then
	  PID=`cat $PID_FILE`
          if [ `ps --pid $PID >/dev/null 2>/dev/null;echo $?` -eq 0 ] ; then
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
