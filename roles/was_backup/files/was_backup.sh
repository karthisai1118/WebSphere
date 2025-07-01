* POSIX shell script, ASCII text executable
#!/bin/sh
#
# Function:
# Backup with tar, gzip the IBM Installation Manager locations of Install directory, Agent Data directory, Shared Resources directory 
# and Installation directory of each Package group in IBM Installation Manager. 
# Also backup file /users/wasadm/etc/.ibm/registry/InstallationManager.dat
#
# Parameters:
# - location_backup is location to store tar, gzip backup files of WebSphere, HTTP Server and IBM Installation Manager locations. 
#
# Changes:
# mm/dd/yy @001 Name Comment
#
# Backup the location with tar, gzip. 
backup () {
	#set -x
	location=$1
	location_backup=$2
	#
	# Check if location exists.
	if [ -d "$location" ] ; then
		  noop=""
	  else
		    echo "Location $location does not exist"
		      exit 1
	fi
	cmd="cd $location"
	echo "$cmd"
	$cmd
	rc=$?
	if [ $rc != 0 ] ; then
		  echo "$cmd failed with return code of $rc"
		    exit 1
	fi
	#
	# Name of tar, gzip file with location change of character / to _ 
	file=`echo $location|tr '[/]' '[_]'`
	#
	# Remove existing tar, gzip file from previous backup.
	cmd="rm -f $location_backup/$file*"
	echo "$cmd"
	$cmd
	rc=$?
	if [ $rc != 0 ] ; then
		  echo "$cmd failed with return code of $rc"
		    exit 1
	fi
	#
	# Execute tar command.
	cmd="tar -cf $location_backup/$file.tar ."
	echo "$cmd"
	tar -cf $location_backup/$file.tar .
	rc=$?
	#
	# Return code 2 is return when some files have error message of
	# tar: 0511-180 file is not a valid tar file type with example below
	# tar: 0511-180 ./logs/adminSocket is not a valid tar file type.
	# tar: 0511-180 ./logs/cgisock.19923342 is not a valid tar file type.
	# root@upes:/opt9/IBM/IBMHttpServer/logs # ls -al adminSocket
	# srwx------    1 webserv  webserv           0 Feb 04 17:42 adminSocket
	# root@upes:/opt9/IBM/IBMHttpServer/logs # ls -al cgisock.19923342
	# srwx------    1 nobody   system            0 Feb 04 17:42 cgisock.19923342
	if [ $rc != 0 -a $rc != 2 ] ; then
		  echo "$cmd failed with return code of $rc"
		    exit 1
	fi
	#
	# Execute list all files in tar file to test.
	cmd="cd /tmp"
	echo "$cmd"
	$cmd
	rc=$?
	if [ $rc != 0 ] ; then
		  echo "$cmd failed with return code of $rc"
		    exit 1
	fi
	cmd="tar -tf $location_backup/$file.tar>/tmp/list_tar.out"
	echo "$cmd"
	tar -tf $location_backup/$file.tar>/tmp/list_tar.out
	rc=$?
	if [ $rc != 0 ] ; then
		  echo "$cmd failed with return code of $rc"
		    exit
	fi
	rm -f /tmp/list_tar.out
	#
	# gzip the tar file to reduce space usage
	cmd="gzip $location_backup/$file.tar"
	echo "$cmd"
	gzip $location_backup/$file.tar
	rc=$?
	if [ $rc != 0 ] ; then
		  echo "$cmd failed with return code of $rc"
		    exit 1
	fi
}
#
# Main
#set -x
# 
# Check arguments
if [ "$#" != 1 ] ; then
	  echo "Not equal to 1 argument"
	    echo "Usage: was_backup.sh location_backup"
	      echo "where location_backup is location to store tar, gzip backup files of WebSphere, HTTP Server and IBM Installation Manager locations"
	        exit 1
fi
#
# Create target directory location_backup.
location_backup=$1
if [ -d "$location_backup" ] ; then
	  noop=""
  else
	    cmd="mkdir -p $location_backup"
	      echo "$cmd"
	        $cmd
		  rc=$?
		    if [ $rc != 0 ] ; then
			        echo "$cmd failed with return code of $rc"
				    exit 1
				      fi
fi
#
# Obtain IBM Installation Manager data directory locations.
# IBM Installation Manager data directory locations documented at https://www.ibm.com/support/pages/node/1081113
#
# Obtain directory of IBM Installation Manager Install directory from /users/wasadm/etc/.ibm/registry/InstallationManager.dat 
# statement location=. Below is example.
# location=/opt/IBM/InstallationManager/install
path_install_manager_install=`cat /users/wasadm/etc/.ibm/registry/InstallationManager.dat|grep "location="|cut -d "=" -f2`
#
# Set path where imcl is located.
path_imcl="$path_install_manager_install/eclipse/tools/imcl"
#
# Check if location path_imcl exists.
if [ -f "$path_imcl" ] ; then
	  noop=""
  else
	    echo "File $path_imcl from /users/wasadm/etc/.ibm/registry/InstallationManager.dat location=value with /eclipse/tools/imcl appended does not exist"
	      exit 1
fi
#
# Obtain IBM Installation Manager Agent Data directory that Installation Manager uses to track data associated with the installed products.
path_install_manager_agent_data=`cat /users/wasadm/etc/.ibm/registry/InstallationManager.dat|grep "appDataLocation"|cut -d "=" -f2`
#
# Obtain IBM Installation Manager Shared Resources directory where installation artifacts are stored.
path_install_manager_shared_resourcest=`cat $path_install_manager_agent_data/installRegistry.xml|grep cacheLocation|cut -d '=' -f3|sed -e "s/['>]//g"`
length=`echo $path_install_manager_shared_resourcest|wc -c`
length=`expr $length - 2` # subtract the / and new line character at end
path_install_manager_shared_resources=`echo $path_install_manager_shared_resourcest|cut -c 1-$length`
#
# Output file from command imcl listInstalledPackages
hostname=`hostname`
filelip="$location_backup/listinstalledpackages.$hostname.out"
filelipv="$location_backup/listinstalledpackages.verbose.$hostname.out"
#
# Execute command listInstalledPackages -long.
cmd="$path_imcl listInstalledPackages -long>$filelip"
echo "$cmd"
`$path_imcl listInstalledPackages -long>$filelip`
rc=$?
if [ $rc != 0 ] ; then
	  echo "$cmd failed with return code of $rc"
	    exit 1
fi
#
# Execute command listInstalledPackages -verbose.
cmd="$path_imcl listInstalledPackages -verbose>$filelipv"
echo "$cmd"
`$path_imcl listInstalledPackages -verbose>$filelipv`
rc=$?
if [ $rc != 0 ] ; then
	  echo "$cmd failed with return code of $rc"
	    exit 1
fi
#
# Backup file /users/wasadm/etc/.ibm/registry/InstallationManager.dat
cmd="cp -p /users/wasadm/etc/.ibm/registry/InstallationManager.dat $location_backup"
echo "$cmd"
$cmd
rc=$?
if [ $rc != 0 ] ; then
	  echo "$cmd failed with return code of $rc"
	    exit 1
fi
#
# Perform backups of IBM Installation Manager locations with tar, gzip command.
backup $path_install_manager_install $location_backup
backup $path_install_manager_agent_data $location_backup
backup $path_install_manager_shared_resources $location_backup
#
# Perform backups of Installation directory of each Package group in IBM Installation Manager.
# Add grep -v 'com.ibm.cic.agent' to not backup IBM Installation Manager Install directory that was backed up earlier.
fileout="/tmp/install_manager_installation_directories.out"
cmd="cat $filelip|grep -v 'com.ibm.cic.agent'|cut -d ':' -f1|sort|uniq>$fileout"
echo "$cmd"
cat $filelip|grep -v 'com.ibm.cic.agent'|cut -d ':' -f1|sort|uniq>$fileout
rc=$?
if [ $rc != 0 ] ; then
	  echo "$cmd failed with return code of $rc"
	    exit 1
fi
while read line
do
	  backup $line $location_backup
  done < $fileout
  rm -f $fileout
  exit 0


