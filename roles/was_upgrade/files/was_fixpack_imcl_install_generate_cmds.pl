#!/usr/bin/perl -w
#
# Function:
# Generate WebSphere Installation Manager imcl install commands from 
# - downloaded WebSphere V8, V9 or higher version fixpack 
#
# Parameters:
# - NFS mounted location of WebSphere fixpack
#
# Output:
# File /tmp/was_imcl_install_fixpack.cmds that is input file to script was_imcl_install.sh.
#
# Change History:
# 03/20/18 @001 Mike McIntyre Parameter path_file_imcl does not need to be written to cmds file due to 
# script was_imcl_install.sh determines from file /users/wasadm/etc/.ibm/registry/InstallationManager.dat statement location=
# 06/28/18 @002 Mike McIntyre Obtain IBM Installation Manager install directory from /users/wasadm/etc/.ibm/registry/InstallationManager.dat
# statement location=. Below is example.
# location=/opt/IBM/InstallationManager/install
# Parameter for path/imcl of Installation Manager imcl command does not to be specified and removed.
# 01/13/20 @003 Mike McIntyre Remove output of variables filesystem, filesystem_free_mb, userid, group due to Ansible workflow was_upgrade.yml 
# has variables and tasks to check filesystem free space in MB and change ownership of WebSphere installation directory location.
# 
# Date, Who, Comment
#
use strict;
#
my $cmd="";
my $file_imcl_cmds="/tmp/was_imcl_install_fixpack.cmds";
my $file_imcl_listInstalledPackages="/tmp/was_imcl_listInstalledPackages.out";
my $file_imcl_listAvailablePackages="/tmp/was_imcl_listAvailablePackages.out";
my ($install_directory,$package_version,$package_versiona,$package_name,$package_path);
my ($len,$len2,$n,$nli,$nlile,$nla,$nlale);
# Logfile with -log option for imcl commands.
my $logfile="/tmp/was_imcl_fixpack.log";
my $msg;
my ($path_imcl_dir,$path_file_imcl);
my $pos;
my $noop;
my $path_nfs;
my $rc;
my $rcerr = 1;
#
# Arrays
my @listInstalledPackages_install_directory;
my @listInstalledPackages_package_version;
my @listAvailablePackages_package_path;
my @listAvailablePackages_package_version;
#
# @002 Check for required one argument of
# - NFS mounted location of WebSphere fixpack.
if (@ARGV != 1) {
  print "Usage: was_fixpack_imcl_install_generate_cmds.pl path_nfs\n";
  print "where parameter path_nfs is NFS mounted path where WebSphere fixpack is located\n";
  exit $rcerr;
}
$path_nfs = $ARGV[0]; # NFS mounted path where WebSphere fixpack is located.
#
# @002. Obtain directory of IBM Installation Manager install directory from /users/wasadm/etc/.ibm/registry/InstallationManager.dat
# statement location=. Below is example.
# location=/opt/IBM/InstallationManager/install
$path_imcl_dir=`cat /users/wasadm/etc/.ibm/registry/InstallationManager.dat|grep "location="|cut -d "=" -f2`;
chomp $path_imcl_dir;
#
# @002 Set path where imcl is located.
$path_file_imcl="$path_imcl_dir/eclipse/tools/imcl";
#
if (-X $path_file_imcl) {
  $noop = " ";
} else {
  print "$path_file_imcl not found or not executable\n";
  exit $rcerr;
}
#
if (-d $path_nfs) {
  $noop = " "; 
} else {
  print "Location $path_nfs not found\n";
  exit $rcerr;
}
#
# Execute command imcl listInstalledPackages to get com.ibm packages installed for each installation directory.
$cmd="$path_file_imcl listInstalledPackages -long|grep com.ibm|sort 1>$file_imcl_listInstalledPackages 2>$file_imcl_listInstalledPackages";
print "$cmd\n";
$rc = system($cmd);
$rc = "$?";
if ($rc != 0) {
  $msg = "$cmd failed with return code of $rc";
  print "$msg\n";
  exit $rcerr;
}
#
# Clear out content in output file for command imcl listAvailablePackages
$cmd="cat /dev/null>$file_imcl_listAvailablePackages";
print "$cmd\n";
$rc = system($cmd);
$rc = "$?";
if ($rc != 0) {
  $msg = "$cmd failed with return code of $rc";
  print "$msg\n";
  exit $rcerr;
}
#
# Get list of subdirectories in NFS mounted path where WebSphere fixpack is located to execute imcl listAvailablePackages.
opendir my $dh, $path_nfs
  or die "$0: opendir: $!";
while (defined(my $name = readdir $dh)) {
  next unless -d "$path_nfs/$name";
  next if $name eq '.' or $name eq '..';
  $cmd="$path_file_imcl listAvailablePackages -repositories $path_nfs/$name -long 1>>$file_imcl_listAvailablePackages 2>>$file_imcl_listAvailablePackages";
  print "$cmd\n";
  $rc = system($cmd);
  $rc = "$?";
  if ($rc != 0) {
    $msg = "$cmd failed with return code of $rc";
    print "$msg\n";
    exit $rcerr;
  }
}
#
# Read file /tmp/was_imcl_listInstalledPackages.out into arrays.
open(file_imcl_listInstalledPackages_fh,"<$file_imcl_listInstalledPackages") || die "open failed for $file_imcl_listInstalledPackages";
$n=0;
while (my $line = <file_imcl_listInstalledPackages_fh>) {
  chomp $line;
  ($install_directory, $package_version, $package_name) = split(/:/, $line);
  $install_directory =~ s/\s//g;
  $pos = index($package_version, "_");
  $package_versiona = substr($package_version,1,$pos);
  $package_versiona =~ s/\s//g;
  $listInstalledPackages_install_directory[$n] = $install_directory;   
  $listInstalledPackages_package_version[$n] = $package_versiona;
  $n = $n + 1;   
}
close file_imcl_listInstalledPackages_fh;
#
# Read file /tmp/was_imcl_listAvailablePackages into arrays.
open(file_imcl_listAvailablePackages_fh,"<$file_imcl_listAvailablePackages") || die "open failed for $file_imcl_listAvailablePackages";
$n=0;
while (my $line = <file_imcl_listAvailablePackages_fh>) {
  chomp $line;
  ($package_path, $package_version, $package_name) = split(/:/, $line);
  $package_path =~ s/\s//g;
  $package_version =~ s/\s//g;
  $listAvailablePackages_package_path[$n] = $package_path;
  $listAvailablePackages_package_version[$n] = $package_version;
  $n = $n + 1;
}
close file_imcl_listAvailablePackages_fh;
#
# Open output file for variables and generated imcl install commands.
open(file_imcl_cmds_fh,">$file_imcl_cmds") || die "open failed for $file_imcl_cmds";
# @001 print file_imcl_cmds_fh "path_file_imcl=$path_file_imcl # path/imcl for full path with imcl command\n";
print file_imcl_cmds_fh "path_nfs=$path_nfs # NFS mounted path where WebSphere fixpack is located\n";
#
# Generate imcl install commands.
$nlale = $#listAvailablePackages_package_version; # Last element of array listAvailablePackages_package_version 
$nlile = $#listInstalledPackages_package_version; # Last element of array listInstalledPackages_package_version
# 
# Loop through listAvailablePackages_package_version.
for ($nla=0; $nla<=$nlale; $nla++) 
{
#
# For each element of listAvailablePackages_package_version, loop through each element of listInstalledPackages_package_version 
# to find match.
  for ($nli=0; $nli<=$nlile; $nli++)
  {
    $pos = index($listAvailablePackages_package_version[$nla], $listInstalledPackages_package_version[$nli]);
    if ( $pos != -1 ) {
      print file_imcl_cmds_fh "install $listAvailablePackages_package_version[$nla] -repositories $listAvailablePackages_package_path[$nla] -installationDirectory $listInstalledPackages_install_directory[$nli] -log $logfile -acceptLicense\n";
    }
  }
}
close file_imcl_cmds_fh;
print "\nFile $file_imcl_cmds contains imcl install commands for script was_imcl_install.sh to execute with first parameter of this file\n";
exit 0;
