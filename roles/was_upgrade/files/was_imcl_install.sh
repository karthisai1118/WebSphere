* ASCII text
#
# Function
#
# Install WebSphere ND fix pack and/or ifixes.
# Also can rollback fix pack or uninstall ifixes.
# Installation Manager is used for WAS V8, V9.
#
# Parameters: 
# - file_imcl_cmds is the file containing variables and imcl install, uninstall, rollback commands. 
#
# Change History:
# 10/30/17 Mike McIntyre @001 Remove versionInfo.sh output. Only need imcl listInstalledPackages -long 
# for WAS V8, V9.
# 02/01/18 Mike McIntyre @002 Add second optional parameter of skip with values of yes or no.
# BigFix task SIS_WAS_Upgrade will execute this script with second parameter of skip=yes to not execute 
# commands imcl listInstalledPackages -long and chown.
# 02/14/18 Mike McIntyre @003 The file from parameter file_imcl_cmds can contain imcl uninstall command.
# This is to uninstall older WebSphere 8.5 Java 1.7 interim fix before newer interim fix for Java 1.7 is installed.
# 03/08/18 Mike McIntyre @004 Replace cmds file parameter path_file_imcl= with obtain directory of 
# IBM Installation Manager install directory from /users/wasadm/etc/.ibm/registry/InstallationManager.dat 
# statement location=. Below is example.
# location=/opt/IBM/InstallationManager/install
# Above is better method to determine the IM install directory is not in a common location without need for 
# parameter path_file_imcl= in cmds file.
# 10/23/19 Mike McIntyre @005 The file from parameter file_imcl_cmds can contain imcl rollback command.
# 01/10/20 Mike McIntyre @006 Remove subroutine filesystem_freemb(), remove optional second parameter of skip, remove check if path_nfs location exists 
# and remove check of filesystem free space in MB.
#
# Execute argument 1 as command. Check return code if non-zero to exit with non-zero exit code.
exec_cmd() {
	#set -x
	cmdi=$1
	echo "$cmdi"
	$cmdi
	#su - $userid -c "$cmdi"
	rc=$?
	if [ $rc != 0 ] ; then
		  echo "$cmdi failed with return code of $rc"
		    echo "Check log file from parameter -log on imcl install command for error messages."
		      echo "After error fixed, script was_imcl_install.sh can be executed again."
		        echo "Execution of same imcl install command again that was previously successful will not cause error."
			  echo "For faster execution, comment out previous install commands that were succcessful from file $file_imcl_cmds."
			    echo "Execute command $path_file_imcl viewlog to find out where Installation Manager log files are stored if needed for further troubleshooting."
			      exit 1
	fi
}
#
# Main Routine
#
#set -x
if [ "$#" != 1 ] ; then
	  echo "Usage: was_imcl_install.sh file_imcl_cmds"
	    echo "where file_imcl_cmds is the file containing variables and imcl install, uninstall, rollback commands. For example."
	      echo "was_imcl_install.sh /tmp/was_imcl_install.cmds"
	        exit 1
fi
file_imcl_cmds="$1"
#
# Check if location for first parameter of file_imcl_cmds exists.
if [ -f "$file_imcl_cmds" ] ; then
	  noop=""
  else
	    echo "$file_imcl_cmds does not exist"
	      exit 1
fi
#
# @004. Obtain directory of IBM Installation Manager install directory from /users/wasadm/etc/.ibm/registry/InstallationManager.dat
# statement location=. Below is example.
# location=/opt/IBM/InstallationManager/install
path_imcl_dir=`cat /users/wasadm/etc/.ibm/registry/InstallationManager.dat|grep "location="|cut -d "=" -f2`
#
# @004 Set path where imcl is located.
path_file_imcl="$path_imcl_dir/eclipse/tools/imcl"
#
# Get variables from file_imcl_cmds.
#
path_nfs=`cat $file_imcl_cmds|grep ^path_nfs=|cut -d "=" -f2|cut -d "#" -f1|tr -d ' '`
if [ -z "$path_nfs" ] ; then
	  print "Variable path_nfs beginning in line of file $file_imcl_cmds does not exist"
	    exit 1
fi
#
# Check if location for command imcl exists.
if [ -f "$path_file_imcl" ] ; then
	  noop=""
  else
	    echo "$path_file_imcl does not exist"
	      exit 1
fi
#
# Check if NFS mounted location of path_nfs exists.
if [ -d "$path_nfs" ] ; then
	  noop=""
  else
	    echo "Directory location $path_nfs does not exist"
	      echo "Check if correct location NFS mounted with $path_nfs"
	        exit 1
fi
#
# Read lines of parameter file_imcl_cmds.
# When line starts with install or uninstall or rollback, execute the imcl install or uninstall or rollback command.
while read line
do
	  install=`echo $line|cut -c 1-7`
	    uninstall=`echo $line|cut -c 1-9` # @003
	      rollback=`echo $line|cut -c 1-8` # @005
	        if [ "$install" == "install" -o "$uninstall" == "uninstall" -o "$rollback" == "rollback" ] ; then 
			    cmd="$path_file_imcl $line"
			        exec_cmd "$cmd"
				  fi
			  done < $file_imcl_cmds
			  #
			  exit 0


