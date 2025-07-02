#!/bin/sh
#
# Function:
# Check syntax of file /etc/rc.was.config.
# Check number of entries for 2nd field userid in /etc/rc.was.config against number of java processes for same userid.
#
# Parameters: None
#
# Changes:
#
# Check if syntax correct for /etc/rc.was.config
check_was_config_syntax () {
#set -x
while read line
do
  process=`echo $line|cut -d ';' -f1`
  if [ $process != 'dmgr' -a $process != 'nodeagent' -a $process != 'appsrv' ] ; then
    echo "$line"
    echo "First field of $process is not value of dmgr or nodeagent or appsrv"
    error_flag_was_config_syntax="Y"
  fi
  userid=`echo $line|cut -d ';' -f2`
#
# Check if userid exists.
  count=`cat /etc/passwd|cut -d":" -f1|grep $userid|wc -l`
  if [ $count -eq 0 ] ; then
    echo "$line"
    echo "Userid $userid does not exist"
    error_flag_was_config_syntax="Y"
  fi
#
# Check if path exists.
  path=`echo $line|cut -d ';' -f3`
  if [ -d "$path" ] ; then
    noop=""
  else
    echo "$line"
    echo "Directory $path does not exist"
    error_flag_was_config_syntax="Y" 
  fi
#
# Check if synch option value of synch or asynch.
  synch_opt=`echo $line|cut -d ';' -f4`
  if [ $synch_opt != 'synch' -a $synch_opt != 'asynch' ] ; then
    echo "$line"
    echo "Fourth field of $synch_opt is not value of synch or asynch"
    error_flag_was_config_syntax="Y"
  fi
#
# Check if fifth field has a value when first field for process is appsrv.
  if [ $process == 'appsrv' ] ; then
    profile=`echo $line|cut -d ';' -f5`
    if test -z "$profile" ; then
      echo "$line"
      echo "Fifth field for profile has no value with first field of appsrv"
      error_flag_was_config_syntax="Y"
    fi
  fi
done < $file_was_config
}
#
# Check number of entries for 2nd field userid in /etc/rc.was.config against number of java processes for same userid.
check_userids_counts() {
#set -x
#
# Number of 2nd field userid entries in file /etc/rc.was.config are stored into arrays userid_name and user_count.
file_was_userids="/tmp/was_userids.out"
#
cat $file_was_config|cut -d ";" -f2>$file_was_userids
rc=$?
#
# Check if non-zero return code.
if [ $rc != 0 ] ; then
  echo "cat $file_was_config|cut -d ";" -f2>$file_was_userids failed with return code of $rc"
  exit 1
fi
current_userid="none"
count=0
i=0
j=0
while read userid
do
  if [ $j -eq 0 ] ; then
    current_userid=$userid
    j=`expr $j + 1`
  fi
  if [ "$userid" != "$current_userid" ] ; then
    userid_name[$i]="$current_userid"
    userid_count[$i]=$count
    current_userid=$userid
    count=0
    i=`expr $i + 1`
  fi
  count=`expr $count + 1`
done < $file_was_userids
#
# Check number of entries for 2nd field userid in file /etc/rc.was.config against number of java processes with same userid.
userid_name[$i]="$current_userid"
userid_count[$i]=$count
length=${#userid_name[@]}
max=`expr $length - 1`
i=0
while [ $i -le $max ]
do
  countp=`ps -ef|grep ${userid_name[$i]}|grep WebSphere|grep -v grep|wc -l`
  countp=`echo $countp|sed 's/ //g'`
  if [ $countp -ne ${userid_count[$i]} ] ; then
    echo "$file_was_config for userid ${userid_name[$i]} has ${userid_count[$i]} entries and there are $countp java processes with userid ${userid_name[$i]}"
    error_flag_fail_process_count="Y"
  fi 
  i=`expr $i + 1`
done
rm -f $file_was_userids
}
#
# Main
# set -x 
error_flag_fail_process_count="N"
error_flag_was_config_syntax="N"
file_was_config="/etc/rc.was.config"
#
if [ -f "$file_was_config" ]
then
  noop=" "
else
  echo "File $file_was_config not found"
  exit 1
fi
#
echo "Check syntax in file /etc/rc.was.config"
check_was_config_syntax
if [ $error_flag_was_config_syntax == "Y" ] ; then
  echo "There were syntax errors in file $file_was_config"
fi
#
echo " "
echo "Check number of entries for 2nd field userid in /etc/rc.was.config against number of java processes for same userid"
check_userids_counts
#
if [ $error_flag_was_config_syntax == "Y" -o $error_flag_fail_process_count == "Y" ] ; then
  exit 1
fi
echo "Number of entries for 2nd field userid in /etc/rc.was.config matches number of java processes for same userid" 
exit 0
