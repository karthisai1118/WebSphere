#!/bin/sh
#
# Function:
# NFS unmount and NFS mount if parameters of nfs_server_ipaddress:nfs_server_directory not already 
# mounted on mountpoint.
#
# Used by BigFix task SIS_WAS_Upgrade to execute Installation Manager imcl install commands for 
# install of WebSphere fix pack and interim fixes.
#
# Parameters:
# - nfs_server_ipaddress for IP address of the NFS server.
# - nfs_server_directory for NFS server directory exported.
# - mountpoint is the location mounted on the NFS client.
#
if [ "$#" != 3 ] ; then
  echo "Usage: nfs_unmount_mount.sh nfs_server_ipaddress nfs_server_directory mountpoint"
  echo "where nfs_server_ipaddress for IP address of the NFS server"
  echo "where nfs_server_directory for NFS server directory exported"
  echo "where mountpoint is the location mounted on the NFS client"
  exit 1
fi
nfs_server_ipaddress=$1
nfs_server_directory=$2
mountpoint=$3
#
check_mount="$nfs_server_ipaddress:$nfs_server_directory"
count=`df -m $mountpoint|grep $check_mount|wc -l|tr -d ' '`
if [ $count -eq 0 ]; then 
  cmd="umount $mountpoint"
  echo "$cmd"
  $cmd
  os=`uname`
  if [ $os == 'AIX' ] ; then
# From http://www-01.ibm.com/support/docview.wss?uid=isg3T1000590
    cmd="/usr/sbin/nfso -o nfs_use_reserved_ports=1"
    echo $cmd
    $cmd
    rc=$?
    if [ $rc != 0 ] ; then
      echo "$cmd failed with return code of $rc"
      exit 1
    fi
  fi
  cmd="mount $nfs_server_ipaddress:$nfs_server_directory $mountpoint"
  echo "$cmd"
  $cmd
  rc=$?
  if [ $rc != 0 ] ; then
    echo "$cmd failed with return code of $rc"
    exit 1
  fi
fi
exit 0
