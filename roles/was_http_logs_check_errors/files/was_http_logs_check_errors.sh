#!/bin/sh
#
# Function
#
# To check for error messages in WebSphere SystemOut.log, SystemErr.log log files. 
# To check for error messages in IBM HTTP Server error_log_*, http_plugin_log_* log files.
# For log files that are located in filesystems that start with second parameter value with default of /logs.
#
# Parameters:
# Optional first parameter days for number of days for log file modification less than days x 24 hours ago. Default is 2 days.
# Optional second parameter for filesystems that starts with to search for WebSphere, HTTP logs. Default is /logs.
# 
# Changes:
# 10/04/17 Mike McIntyre @001 Skip count for userid was7 due to userid was1 has path of
# /opt/was7/WebSphere/AppServer/profiles/AppSrv01/bin. This causes process count to not be accurate for userid was7.
# 10/13/17 Mike McIntyre @002 Filter out individual warning messages that are not important.
# 01/11/18 Mike McIntyre @003 Changes days from 2 to 1 for find.
# 02/01/18 Mike McIntyre @004 Do not exit 1 with variable error_flag_fail_log of Y. This script will be used by
# BigFix task SIS_WAS_Upgrade with file was_http_logs_check_errors.out uploaded to BigFix server for review.
# 02/01/18 Mike McIntyre @005 Add second optional parameter of skip with values of yes or no.
# BigFix task SIS_WAS_Upgrade will execute this script with second parameter of skip=yes to not 
# check number of entries for userid in /etc/rc.was.config against number of java processes for same userid.
# If multiple WAS application servers are started in background with /etc/rc.was.config entries of asynch, 
# there can be additional java processes while initializing to exit with a non-zero exit code.
# 02/15/18 Mike McIntyre @006 Filter out http_plugin_log_* STATS:, DEBUG:, DETAIL: messages.
# 06/29/18 Mike McIntyre @007 Change find_logfiles 'SystemOut*' to find_logfiles 'SystemOut.log' and 
# find_logfiles 'SystemErr*' to find_logfiles 'SystemErr.log'. To only return these files for startup messages.
# 01/10/20 Mike McIntyre @008 Remove code for change @001 for userid was7.
# 01/10/20 Mike McIntyre @009 Add parameter for filesystems that start with that contain WebSphere, HTTP log files.
#
# Find fileystems with starting name.
find_filesystems() {
#set -x
name=$1
os=$2
logfile=$3
#
error_flag="Y"
if [ $os = 'AIX' ] ; then
  error_flag="N"
  cmd="df -m|awk '{ print $7 }'|grep ^$name>$logfile"
# echo "$cmd"
  df -m|awk '{ print $7 }'|grep ^$name>$logfile
fi
if [ $os = 'Linux' ] ; then
  error_flag="N"
  cmd="df -m|awk '{ print $6 }'|grep ^$name>$logfile"
# echo "$cmd"
  df -m|awk '{ print $6 }'|grep ^$name>$logfile
fi
rc=$?
#
if [ $error_flag == 'Y' ] ; then
  "Operating system of $os is not supported"
  exit 1
fi
#
if [ $rc != 0 ] ; then
  echo "$cmd failed with return code of $rc"
fi
}
#
# For filesystems that start with filesystem_starts_with
# Find log files to check for error messages.
find_logfiles() {
#set -x
namef=$1
logfile=$2
filesystems_logs=$3
filesystem_starts_withi=$4
while read filesystem_log
do
#
# -mtime -$days finds file modified less than n*24 hours ago.  
  cmd="find $filesystem_log -type f -mtime -$days -name $namef|grep '^$filesystem_starts_withi|grep -v gz'>>$logfile"
# echo "$cmd"
  find $filesystem_log -type f -mtime -$days -name "$namef"|grep '^filesystem_starts_withi'|grep -v gz>>$logfile
  rc=$?
#
# Check if non-zero return code on find to output warning message.
  if [ $rc != 0 -a $rc != 1 -a $rc != 2 ] ; then
    echo "$cmd failed with return code of $rc or no files found"
  fi
done < $filesystems_logs
}
#
# Check for error messages in WebSphere log files of SystemOut.log, SystemErr.log.
check_errors() {
#set -x
logfiles=$1
#
# Check if $logfiles exists.
if [ -f "$logfiles" ] ; then
  noop=""
else
  echo "File $logfiles does not exist"
  exit 1
fi
#
# Check each WebSphere log file of SystemOut.log, SystemErr.log for errors.
fileso="SystemOut"
filese="SystemErr"
# Check IBM HTTP log files of error_log_*, http_plugin_log_* for errors.
filehe="error_log"
filehp="http_plugin_log"
echo " "
while read line
do
#
# Check if file is WebSphere SystemOut.log
  if test "${line#*$fileso}" != "$line"
  then
    echo "WebSphere log file $line"
# 
# Check if there is a message of:
# WsServerImpl  A   WSVR0001I: Server $name open for e-business
    count=`grep -E "open for e-business" $line|wc -l`
    if [ -z "$count" ] ; then 
      count=0
    fi
    if [ $count -lt 1 ] ; then
      echo "No message WSVR0001I: Server name open for e-business"
      error_flag_fail_log="Y"
    fi
#
# Check if there is E: for Error messages.
    count=`grep -E "E:" $line|wc -l`
    if [ -z "$count" ] ; then 
      count=0
    fi
    if [ $count -ge 1 ] ; then
      echo "Error messages containing E:"
      error_flag_fail_log="Y"
    fi
#
# Check if there is W: for Warning messages.
    count=`grep -E "W:" $line|grep -v -E "$msgs_exclude"|wc -l` # @002
    if [ -z "$count" ] ; then
      count=0
    fi
    if [ $count -ge 1 ] ; then
      echo "Warning messages containing W:"
      error_flag_fail_log="Y"
    fi
#
# Output all messages for the log file.
# Below is example of error message for tiSalesGatewayServlet that does not use error message ending with E: 
# Need to output all matching messages for tiSalesGatewayServlet 
# [6/12/17 11:33:24:887 GMT] 0000007f SystemOut O tiSalesGatewayServlet: Exception - Failed to initialize queues: See trace log
    grep -E "e-bus|E:|W:|tiSalesGatewayServlet" $line|grep -v -E "$msgs_exclude"  # @002
    echo " "
  fi
#
# Check if file is WebSphere log file SystemErr.log
  if test "${line#*$filese}" != "$line"
  then
    echo "WebSphere log file $line"
#
# File SystemErr.log contains the following messages when no error messages at startup.
# Check if other messages that are not messages below.
# ************ Start Display Current Environment ************
# Log file started at: [10/4/17 0:00:00:227 GMT]
# ************* End Display Current Environment *************
    count=`grep -v -E "Display Current Environment|Log file started at:" $line|wc -l`
    if [ -z "$count" ] ; then
      count=0
    fi
    if [ $count -ge 1 ] ; then
      echo "Other WebSphere SystemErr.log messages to check"
      error_flag_fail_log="Y"
    fi
#
# Output all other SystemErr.log messages.
    grep -v -E "Display Current Environment|Log file started at:" $line
    echo " "
  fi
#
# Check if file is IBM HTTP Server error_log_*
  if test "${line#*$filehe}" != "$line"
  then
    echo "IBM HTTP server log file $line"
#
# File error_log_* contains :notice messages when no error, warning messages at startup.
# Check if other messages that are not messages below.
# [Wed Sep 20 06:57:46.039912 2017] [mpmstats:notice] [pid 12124232:tid 1] mpmstats: rdy 99 bsy 1 rd 0 wr 0 ka 0 log 0 dns 0 cls 1
# [Mon Sep 11 22:42:18.033352 2017] [was_ap24:notice] [pid 14418152:tid 1] WebSphere Plugins loaded.
# From IBM HTTP Server V9
# [Mon Oct 02 00:00:47 2017] [info] [client 125.101.0.75:49361] [110a2c410] Session ID: session_id_value
# [debug] connection.c(190): [client 125.101.0.75:49361] ap_lingering_close exit
    count=`grep -v -E ":notice|[debug]|[info]" $line|wc -l`
    if [ -z "$count" ] ; then
      count=0
    fi
    if [ $count -ge 1 ] ; then
      echo "Other IBM HTTP Server error_log messages to check"
      error_flag_fail_log="Y"
    fi
#
# Output all other error_log_* messages.
    grep -v -E ":notice|[debug]|[info]" $line
    echo " "
  fi
#
# Check if file is IBM HTTP Server http_plugin_log_*
  if test "${line#*$filehp}" != "$line"
  then
    echo "IBM HTTP server log file $line"
#
# File http_plugin_log_* contains PLUGIN: messages when no error, warning messages at startup.
# Check if other messages that are not messages containing PLUGIN:, STATS:, DEBUG:, DETAIL:. @006
# [11/Sep/2017:18:43:58.84049] 006a00f8 00000001 - PLUGIN: Plugins loaded.
# [06/Oct/2017:19:06:43.24773] 00ea003e 00001617 - STATS: ws_server_group: serverGroupCheckServerStatus: Checking status of megaNode01_tisales3, 
# ignoreWeights 1, markedDown 0, retryNow 0, retryInSec --, wlbAllows 0 reachedMaxConnectionsLimit 0
# Example of an error message:
# [11/Sep/2017:18:45:20.32131] 00450084 00000203 - ERROR: ws_common: websphereGetStream: Failed to connect to app server on host 'popeye' (79): 
# Connect (local port 4096)
    count=`grep -v -E "PLUGIN:|STATS:|DEBUG:|DETAIL:" $line|wc -l`
    if [ -z "$count" ] ; then
      count=0
    fi
    if [ $count -ge 1 ] ; then
      echo "Other IBM HTTP Server error_log messages to check"
      error_flag_fail_log="Y"
    fi
#
# Output all other error_log_* messages.
    grep -v -E "PLUGIN:|STATS:|DEBUG:|DETAIL:" $line
    echo " "
  fi
done < $logfiles
}
#
# Main Routine
#
# Optional parameter days for number of days for log file modification less than days x 24 hours ago.
# -mtime -$days finds file modified less than n*24 hours ago.
# @003
days=1
if [ "$#" -eq 1 -o "$#" -eq 2 ] ; then
  days="$1"
fi
#
# @009 Optional second parameter of filesystems that starts with for WebSphere, HTTP logs. Defaults to /logs if not specified.
filesystem_starts_with="/logs"
if [ "$#" == 2 ] ; then
  filesystem_starts_with="$2"
fi
#
# Check if variable days is a integer
if echo $days | egrep -q '^[0-9]+$'; then
  noop=" "
else
  echo "Optional first parameter days is not an integer for command find -mtime -days"
  exit 1
fi
#
error_flag_fail_log="N"
#
# Contains WebSphere, IBM HTTP filesystems that start with variable filesystem_starts_with.
filesystems_was_http_logs="/tmp/filesystems_was_http_logs_check_errors.out"
#
# Configuration file of WebSphere deployment managers, nodeagents and application servers to stop, start.
file_was_config="/etc/rc.was.config"
#
# @002 Variable msgs_exclude are individual warning messages that are not important to filter out with 
# |grep -v -E "$msgs_exclude"
# For -E, add | between each message.
#
# - BBFactoryImpl W CWOBB1009W: Process teraCell03\teraNode03\tiAuditLogger rejoined.
# - BBFactoryImpl W CWOBB1012W: Received message from (process, epoch) (teraCell02\megaNode01\tisales1, 1507346206963) which is not in the 
# current view at time 1508344437273; (process, epoch) in ProcessEpoch is (teraCell02\megaNode01\tisales1, 1507346206963).
# - RegistryCache I CWXRS0002I: DynaCache instance for Extension Registry created with CACHE_SIZE: 5000
# Warning messages DCSV8104W, DCSV1115W are issued when an application server is being stopped.
# - RoleMember W DCSV8104W: DCS Stack DefaultCoreGroup at Member teraCell02\gigaNode01\tisales6 : Removing member [teraCell02\megaNode01\tisales4]
# because the member was requested to be removed  by member teraCell02\gigaNode01\datafeed. Internal details VL suspects others: CC-Situation Normal
# - DiscoveryRcv W DCSV1115W: DCS Stack DefaultCoreGroup at Member teraCell02\gigaNode01\tisales6 : Member teraCell02\megaNode01\tisales4 connection was closed.
# Member will  be removed from view. DCS connection status is Discovery|Ptp, receiver closed. Connection closed by 198.20.11.58:9378||0.
# P2PGroup I ODCF8041I: Detected process teraCell02\megaNode01\tisales4 stopped.
# NGUtil$Server I ASND0003I: Detected server tisales4 stopped on node megaNode01
# - TransportAdap W DCSV1116W: DCS Stack DefaultCoreGroup at Member am03Cell02\am03Node01\aicstools: Member am03Cell02\am03Node01\tiAuditLogger has suspected 
# this member and will remove it from the view
msgs_exclude="CWOBB1009W|CWOBB1012W|CWXRS0002I|DCSV1036W|DCSV1115W|DCSV1116W|DCSV1117W|DCSV1132W|DCSV1134W|DCSV8021W|DCSV8100W|DCSV8104W"
#
# Execute df -m command and find filesystems that start with /logs
os=`uname`
find_filesystems $filesystem_starts_with $os $filesystems_was_http_logs # @009
#
logfiles_check_errors=/tmp/was_http_logfiles_check_errors.out
cat /dev/null>$logfiles_check_errors
rc=$?
if [ $rc != 0 ] ; then
  echo "cat /dev/null>$logfiles_check_errors failed with return code of $rc"
  exit 1
fi
#
# @007, @009 Execute find commands for WebSphere logs.
find_logfiles 'SystemOut.log' $logfiles_check_errors $filesystems_was_http_logs $filesystem_starts_with
find_logfiles 'SystemErr.log' $logfiles_check_errors $filesystems_was_http_logs $filesystem_starts_with
#
# Execute find commands for IBM HTTP server error logs.
find_logfiles '*error_log_*' $logfiles_check_errors $filesystems_was_http_logs $filesystem_starts_with
find_logfiles '*http_plugin_log_*' $logfiles_check_errors $filesystems_was_http_logs $filesystem_starts_with
#
# Below for IBM HTTP Server V7 with one http_plugin.log due to rotatelogs not supported.
find_logfiles 'http_plugin.log' $logfiles_check_errors $filesystems_was_http_logs $filesystem_starts_with
#
hostname=`hostname`
echo " "
echo "Checking WebSphere log files SystemOut.log, SystemErr.log and IBM HTTP Server log files *error_log_*, *http_plugin_log_*, http_plugin.log on $hostname"
#
# Check if errors in WebSphere log files for SystemOut.log, SystemErr.log.
check_errors $logfiles_check_errors
#
# Delete output files in /tmp
rm -f $logfiles_check_errors
rm -f $filesystems_was_http_logs
#
# Check if some WebSphere, HTTP logfiles had error messages.
if [ $error_flag_fail_log == "Y" ] ; then
  echo " "
  echo "Some WebSphere, IBM HTTP server log files had error, warning messages to review"
# exit 1 @004
fi
exit 0
