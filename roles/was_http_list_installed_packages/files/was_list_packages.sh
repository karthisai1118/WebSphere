* POSIX shell script, ASCII text executable
#!/bin/sh
#
# Function:
# Execute the following IBM Installation Manager commands for WebSphere V8, V9, etc. servers.
# imcl listInstalledPackages -long>/tmp/was/listinstalledpackages_hostname.out
# imcl listInstalledPackages -verbose>/tmp/was/listinstalledpackages_verbose_hostname.out
#
# Changes:
#
#set -x
#
# Obtain directory of IBM Installation Manager install directory from /etc/.ibm/registry/InstallationManager.dat 
# statement location=. Below is example.
# location=/opt/IBM/InstallationManager/install
path_imcl_dir=`cat /users/wasadm/etc/.ibm/registry/InstallationManager.dat|grep "location="|cut -d "=" -f2`
#
# Set path where imcl is located.
path_imcl="$path_imcl_dir/eclipse/tools/imcl"
#
# Check if location path_imcl exists.
if [ -f "$path_imcl" ] ; then
	  noop=""
  else
	    echo "File $path_imcl from /users/wasadm/etc/.ibm/registry/InstallationManager.dat location=value with /eclipse/tools/imcl appended does not exist"
	      exit 1
fi
#
# Create target directory /tmp/output/was for output files of imcl listInstalledPackages commands.
dir_was="/tmp/output/was"
if [ -d "$dir_was" ] ; then
	  noop=""
  else
	    cmd="mkdir -p $dir_was"
	      echo "$cmd"
	        $cmd
		  rc=$?
		    if [ $rc != 0 ] ; then
			        echo "$cmd failed with return code of $rc"
				    exit 1
				      fi
fi
#
# Output files from command imcl listInstalledPackages
hostname=`hostname`
filelip="$dir_was/listinstalledpackages.$hostname.out"
filelipv="$dir_was/listinstalledpackages.verbose.$hostname.out"
#
# Execute command listInstalledPackages -long.
cmd="$path_imcl listInstalledPackages -long>$filelip"
echo "$cmd"
su - wasadm -c `$path_imcl listInstalledPackages -long>$filelip`
rc=$?
if [ $rc != 0 ] ; then
	  echo "$cmd failed with return code of $rc"
	    exit 1
fi
#
# Execute command listInstalledPackages -verbose.
cmd="$path_imcl listInstalledPackages -verbose>$filelipv"
echo "$cmd"
su - wasadm -c `$path_imcl listInstalledPackages -verbose>$filelipv`
rc=$?
if [ $rc != 0 ] ; then
	  echo "$cmd failed with return code of $rc"
	    exit 1
fi
exit 0
