#!/bin/bash

# -------------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <andreas@schipplock.de> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return Andreas Schipplock
# -------------------------------------------------------------------------------

function exit-apache {
  echo "killing apache..."
  apache_pidfile="/var/run/apache2/apache2.pid"
  if [ ! -f ${apache_pidfile} ]; then
    exit 0
  fi
  apache_pid=$(cat ${apache_pidfile} 2> /dev/null)
  kill -TERM ${apache_pid} 2> /dev/null
  while :
  do
    echo "killing apache..."
    if [ ! -f ${apache_pidfile} ]; then
      echo "apache has been shut down successfully"
      break
    fi
    sleep 1
  done
  exit 0
}

apache2ctl -k start

trap exit-apache SIGINT SIGTERM
while :; do sleep 1; done