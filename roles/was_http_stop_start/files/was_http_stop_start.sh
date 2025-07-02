#!/bin/sh
#
# Function:
# To stop or start IBM HTTP server and WebSphere.
# 
# Parameters
# Required first parameter of stop or start.
#
# Change History:
# Date, Who, Comment
# 09/01/2017 Mike McIntyre @001 Add optional second parameter of userid for lines in /etc/rc.was.config with second field of 
# userid to start or stop
# 04/29/2021 Mike McIntyre @002 Scripts rc.http, rc.was for Linux change location from /etc/init.d to /usr/local/bin for 
# Red Hat V8 systemd command systemctl enable service which will fail with error message below if script in /etc/init.d.
# service service does not support chkconfig
#
# Main Routine
#set -x
if [ "$#" != 1 -a "$#" != 2 ] ; then 
  echo "Not equal to 1 or 2 arguments."
  echo "Usage: was_http_stop_start.sh action userid"
  echo "where first parameter action is stop or start"
  echo "where optional second parameter is userid for lines in /etc/rc.was.config with second field of userid to start or stop"
  exit 1
fi
#
# Assign variable action to first parameter.
action=$1
if [ $action != "stop" -a $action != "start" ] ; then
  echo "First parameter of action is not stop or start."
  exit 1
fi
#
# Assign variable userid to second parameter.
if [ "$#" == 1 ] ; then
  userid="no"
fi
if [ "$#" == 2 ] ; then
  userid=$2
fi
#
# Some WebSphere servers may not run IBM HTTP server with no file /etc/rc.http for AIX 
# or no file /usr/local/bin/rc.http for Linux.
#cmdfile="/etc/rc.http"
os=`uname`
if [ $os == 'Linux' ] ; then
  cmdfile="/etc/init.d/APPSVC" # @002
fi
#if [ $os == 'AIX' ] ; then
#  cmdfile="/etc/rc.d/init.d/APPSVC" # @002
#fi
error_http="N"
if [ -f "$cmdfile" ] ; then
#
# Stop or start IBM HTTP server.
  cmd="$cmdfile $action" 
  echo "$cmd"
  $cmd
  rc=$?
#  if [ $rc != 1 ] ; then
#    echo "$cmd failed with return code of $rc"
#    error_http="Y"
#  fi
else
  echo "File $cmdfile does not exist for no IBM HTTP server action of $action"
  echo "Some WebSphere servers may not run IBM HTTP server"
fi
#
# Stop or start WebSphere.
#
# Check if IBM HTTP server failed action of stop or start to exit with non-zero exit code.
#if [ $error_http == "Y" ] ; then
#  echo "IBM HTTP server failed with action of $action"
#  exit 1
#fi
exit 1
~
