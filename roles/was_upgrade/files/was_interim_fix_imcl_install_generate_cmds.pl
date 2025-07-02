#!/usr/bin/perl -w
#
# Function:
# Generate WebSphere Installation Manager imcl install commands from 
# - downloaded WebSphere V8, V9 or higher version interim fixes  
#
# Parameters:
# - NFS mounted location of WebSphere interim fixes.  
#
# Output:
# File /tmp/was_imcl_install_interim_fix.cmds that is input file to script was_imcl_install.sh.
#
# Change History:
# Date, Who, Comment
# 03/20/18 @001 Mike McIntyre Parameter path_file_imcl does not need to be written to cmds file due to 
# script was_imcl_install.sh determines from file /users/wasadm/etc/.ibm/registry/InstallationManager.dat statement location=
# 06/28/18 @002 Mike McIntyre Obtain IBM Installation Manager install directory from /users/wasadm/etc/.ibm/registry/InstallationManager.dat
# statement location=. Below is example.
# location=/opt/IBM/InstallationManager/install
# Parameter for path/imcl of Installation Manager imcl command does not to be specified and removed.
# 01/13/20 @003 Mike McIntyre Remove output of variables filesystem, filesystem_free_mb, userid, group due to Ansible workflow was_upgrade.yml
# has variables and tasks to check filesystem free space in MB and change ownership of WebSphere installation directory location.
#
use strict;
#
my $cmd="";
my ($count,$counte);
my $file_imcl_cmds="/tmp/was_imcl_install_interim_fix.cmds";
my $file_imcl_listInstalledPackages="/tmp/was_imcl_listInstalledPackages.out";
my $file_imcl_listAvailableFixes_stdout="/tmp/was_imcl_listAvailableFixes.stdout";
my $file_imcl_listAvailableFixes_stderr="/tmp/was_imcl_listAvailableFixes.stderr";
my ($full_path,$full_patha);
my ($install_directory,$package_version,$package_version_install,$package_name,$package_path);
my ($len,$len2,$n,$nli,$nlile,$nla,$nlale);
# Logfile with -log option for imcl commands.
my $logfile="/tmp/was_imcl_ifix.log";
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
my @ifix_paths;
#
# @002 Check for required one argument of
# - NFS mounted location of WebSphere interim fix(s).
if (@ARGV != 1) {
  print "Usage: was_interim_fix_imcl_install_generate_cmds.pl path_nfs\n";
  print "where parameter path_nfs is NFS mounted path where WebSphere interim fix(s) are located\n";
  exit $rcerr;
}
$path_nfs = $ARGV[0]; # NFS mounted path where WebSphere interim fix(s) are located.
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
# Get list of subdirectories in NFS mounted path where WebSphere interim fix(s) are located to execute imcl listAvailableFixes
$n=-1; # Needs to be -1 with code to increment variable n for elements of array ifix_paths below
opendir my $dh, $path_nfs
  or die "$0: opendir: $!";
while (defined(my $name = readdir $dh)) {
  next unless -d "$path_nfs/$name";
  next if $name eq '.' or $name eq '..';
  $full_path = "$path_nfs/$name";
  $full_path =~ s/\s//g;
#
# Check if repository.xml exists in full_path for valid imcl repository location.
  if (-e "$full_path/repository.xml") {
    $n = $n + 1;
    $ifix_paths[$n] = "$full_path";
  }
  $full_patha = "$full_path/64bit";
  $full_patha =~ s/\s//g;
#
# Check if ifix Java 64bit subdirectory exists.
  if (-d $full_patha) {
#
# Check if repository.xml exists in full_path for valid imcl repository location.
    if (-e "$full_patha/repository.xml") {    
      $n = $n + 1;
      $ifix_paths[$n] = $full_patha;
    }
  }
  $full_patha = "$full_path/32bit";
  $full_patha =~ s/\s//g;
#
# Check if ifix Java 32bit subdirectory exists.
  if (-d $full_patha) {
#
# Check if repository.xml exists in full_path for valid imcl repository location.
    if (-e "$full_patha/repository.xml") {
      $n = $n + 1; 
      $ifix_paths[$n] = $full_patha;
    }
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
  $package_version =~ s/\s//g;
  $listInstalledPackages_install_directory[$n] = $install_directory;   
  $listInstalledPackages_package_version[$n] = $package_version;
  $n = $n + 1;   
}
close file_imcl_listInstalledPackages_fh;
#
# Open output file for variables and generated imcl install commands.
open(file_imcl_cmds_fh,">$file_imcl_cmds") || die "open failed for $file_imcl_cmds";
# @001 print file_imcl_cmds_fh "path_file_imcl=$path_file_imcl # path/imcl for full path with imcl command\n";
print file_imcl_cmds_fh "path_nfs=$path_nfs # NFS mounted path where WebSphere interim fix(s) are located\n";
#
# Generate imcl install commands.
$nlale = $#ifix_paths; # Last element of array ifix_paths
$nlile = $#listInstalledPackages_package_version; # Last element of array listInstalledPackages_package_version
# 
# Loop through ifix paths.
for ($nla=0; $nla<=$nlale; $nla++) 
{
#
# For each element of ifix_paths, loop through each element of listInstalledPackages_package_version 
# to find match.
  for ($nli=0; $nli<=$nlile; $nli++)
  {
# Execute command imcl listAvailableFixes for each ifix path for all installed com.ibm packages in array listInstalledPackages_package_version
    $cmd="$path_file_imcl listAvailableFixes $listInstalledPackages_package_version[$nli] -repositories $ifix_paths[$nla] 1>$file_imcl_listAvailableFixes_stdout 2>$file_imcl_listAvailableFixes_stderr";
    print "$cmd\n";
    $rc = system($cmd);
    $rc = "$?";
    if ($rc != 0) {
      $msg = "$cmd failed with return code of $rc";
      print "$msg\n";
      exit $rcerr;
     }
    $count = `cat $file_imcl_listAvailableFixes_stdout|wc -l`;
    $counte = `cat $file_imcl_listAvailableFixes_stderr|wc -l`;
#
# If above listAvailableFixes has the package version of the ifix in standard output file, then applicable to output imcl install command
    if ( $count >= 1 and $counte == 0 ) {
      $package_version_install = `cat $file_imcl_listAvailableFixes_stdout`;
      chomp($package_version_install);
      print file_imcl_cmds_fh "install $package_version_install -repositories $ifix_paths[$nla] -installationDirectory $listInstalledPackages_install_directory[$nli] -log $logfile -acceptLicense\n";
    }
  }
}
close file_imcl_cmds_fh;
print "\nFile $file_imcl_cmds contains imcl install commands for script was_imcl_install.sh to execute with first parameter of this file\n";
exit 0;
