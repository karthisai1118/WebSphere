# ansible-role-websphere-upgrade
Upgrade of WebSphere, IBM HTTP Server V9, V8.5 with install of fixpack, interim fix(s)

<h2>Description</h2>
<p>This project contains roles and playbooks to install fixpack and interim fix(s) with IBM Installation Manager install commands. Below is sequenced list of tasks with usage of playbook was_upgrade.</p>
<ol type="1">
<li>WebSphere support person downloads WebSphere Network Deployment (ND), IBM HTTP Server fixpack, interim fixes into a filesystem exported on a NFS server for NFS mount.</li>
<li>Perl scripts executed on a WebSphere ND, IBM HTTP server to generate IBM Installation Manager install commands in a cmds file from WebSphere fixpack, interim fix(s) stored in filesystem exported by NFS server and NFS mounted. See heading <b>Perl Scripts to Generate IBM Installation Manager Commands</b>.</li>
<li>WebSphere support person launch of job template filesystem_freespace to check if filesystem where WebSphere installation directory is located has enough free space on the WebSphere servers. Free space required can be determined from install on first test WebSphere server.</li>
<li>WebSphere support person launch of job template was_syntax_processes_check to check syntax of file /etc/rc.was.config and number of entries for 2nd field userid in /etc/rc.was.config against number of java processes for same userid. This is executed if provided WebSphere, HTTP Server stop, start scripts are used under heading <b>Provided WebSphere, HTTP Server Stop, Start Scripts</b>.</li>
<li>WebSphere support person launch of job template was_backup to tar, gzip the WebSphere, HTTP Server install directories and IBM Installation Manager locations for backup before start of change window. Ansible job template survey option location_backup is directory location to store tar, gzip backup files to check if there is enough allocated disk space.</li>
<li>WebSphere support person launch of job template was_upgrade with survey to input any changes to Ansible variables values. Playbook was_upgrade performs the following tasks.</li>
<ol type="a">
<li>Validates that values of variables are correct with failure message if not correct.</ul>
<li>Checks free space in MB of filesystem from values of Ansible variables filesystem, fileystem_freespace_mb input.</ul>
<li>NFS mount the software repository filesystem from values of Ansible variables server_ipaddress, export_path, mountpoint input if Ansible variable nfs_mount is yes. Default value of yes. Import of Ansible role mount_unmount_software_repository_nfs.</ul>
<li>Check if NFS mounted location from Ansible variable file_cmds value for cmds file of IBM Installation Manager install commands is found. If not found, fail with message.</ul>
<li>Stop WebSphere, IBM HTTP server processes on server. Import of Ansible role was_http_stop_start.</ul>
<li>Execute IBM Installation Manager install commands from Ansible variable file_cmds value for cmds file. NFS mounted location from statement path_nfs= in cmds file is checked if found before execution of install commands. Import of Ansible role was_upgrade.</ul>
<li>Change ownership recursive of WebSphere installation directory from Ansible variables owner, group values.</ul>
<li>Remove other read, write, execute permissions recursive of WebSphere installation directory for GCM WebSphere security configuration compliance.</ul>
<li>Start WebSphere, IBM HTTP server processes on server. Import of Ansible role was_http_stop_start.</ul>
<li>IBM Installation Manager list installed packages with location, package, version. Import of Ansible role was_http_list_installed_packages.</ul>
<li>Check for error, warning messages in WebSphere SystemOut.log, SystemError.log files and IBM HTTP Server error_log_, http_plugin_log_ log files. Ansible variable filesystem_starts_with value for filesystems that starts with for WebSphere, HTTP logs. Ansible variable days value for number of days for log file modification less than. Import of Ansible role was_http_logs_check_errors.</ul>
<li>Unmount the NFS mounted location if Ansible variable nfs_unmount value is yes. Default value of yes. Import of Ansible role mount_unmount_software_repository_nfs.</ul>
</ol>
</ol>

<p>If you do not use NFS.</p>
<ul>
<li> Set Ansible variables nfs_mount, nfs_unmount to value of no to not perform NFS mount, unmount. Add survey prompts for NFS_mount, NFS_unmount with value of no in Ansible job template was_upgrade as documented under heading Creation of Ansible Tower Job Templates with Survey.
<li> Ansible variable file_cmds needs to have a value for location of locally stored file with extension of .cmds containing IBM Installation Manager install or rollback, uninstall commands for WebSphere, HTTP server fixpack and interim fixes.
<li> This locally stored file with extensions of .cmds requires path_nfs=mounted path with a path location that exists so that script was_imcl_install.sh does not fail. This could be the location of locally stored WebSphere, HTTP server fixpack to install.
</ul>

<h3>Tested Backout Procedure documented in Change Ticket</h3>
<p>There should be a backout if the install of WebSphere fixpack, WebSphere V9 Java and/or interim fix(s) experiences problems. The above playbook was_upgrade can execute IBM Installation Manager uninstall, rollback commands in cmds file from Ansible variable file_cmds value. The rollback to the previous WebSphere fixpack, WebSphere V9 Java installed or uninstall of interim fix(s) should be tested on a test WebSphere server after install of fixpack and/or interim fix(s). Document procedure for backout in change ticket to upgrade WebSphere, HTTP servers.</p>
<p>The cmds file containing IBM Installation Manager uninstall, rollback commands to test can be created by one of two methods below.</p>
<ul>
<li>Copy the previous cmds file used to upgrade WebSphere, HTTP Server into another file name like was_imcl_backout_fixpack_was9fpnn_interim_fix.cmds where nn is previous fixpack installed. Change command install for fixpack, WebSphere V9 Java to rollback. Command install for previous interim fix(s) installed remains command install. Move commands install for interim fix(s) after commands for rollback. Change command install for recent interim fix(s) installed to uninstall and move before commands for rollback. Remove parameter -repositories that is not a valid parameter from command uninstall.</li>
or
<li>For first time using this project. Follow procedure under heading <b>Perl Scripts to Generate IBM Installation Manager Commands</b> for NFS mounted locations of previous fixpack, previous interim fix(s) installed. Change command install for fixpack, WebSphere V9 Java to rollback. Command install for previous interim fix(s) installed remains command install. Move commands install for interim fix(s) after commands for rollback. Change command install for recent interim fix(s) installed to uninstall and move before commands for rollback. Remove parameter -repositories that is not a valid parameter from command uninstall.</li>
</ul>
<p>If IBM Installation Manager> Preferences> Files for Rollback does not Save files for rollback, you need to keep the installation media content from imcl listInstalledPackages -verbose Rollback versions and the installation media content when WebSphere was first installed on the server from [Package group] of imcl listInstalledPackages -verbose.</p>
<p>The IBM Installation Manager command imcl rollback parameter -repositories may need to specify both the previous fix pack to rollback to and the installation media content when WebSphere was first installed on the server from [Package group] of imcl listInstalledPackages -verbose.
On the imcl rollback parameter -repositories, these two locations are separated by ,</p>

<h2>Playbooks</h2>
<p>Following are playbooks contained in this project:</p>
<ul>
<li><b>was_upgrade</b> - Upgrade WebSphere, HTTP Server on AIX, Linux with Installation Manager imcl install commands for fixpack and/or interim fixes. The tasks in this playbook were explained.</li>
<li><b>filesystem_freespace</b> - Check free space in MB for filesystem on AIX, Linux servers.</li>
<li><b>mount_unmount_nfs</b> - Mount, unmount the software repository with NFS on AIX, Linux servers.</li>
<li><b>was_backup</b> - To tar, gzip the WebSphere, HTTP Server install directories and IBM Installation Manager locations for backup before start of change window.
The WebSphere, HTTP Server install directory locations are determined from Installation directory of Package group from IBM Installation Manager command listInstalledPackages -long. The IBM Installation Manager locations below are determined and backed up.
<ul>
<li>/etc/.ibm/registry/InstallationManager.dat
<li>IBM Installation Manager Install directory.
<li>IBM Installation Manager Agent Data directory that Installation Manager uses to track data associated with the installed products.
<li>IBM Installation Manager Shared Resources directory where installation artifacts are stored. This location becomes larger in size if IBM Installation Manager> Preferences> Files for Rollback option Save files for rollback is turned on.
</ul>
To prevent tar create command failure with error message of "tar: 0511-194 Reached end-of-file before expected", 
check /etc/security/limits on AIX and /etc/security/limits.conf on Linux for default or userid root to have unlimited file size with fsize of -1
<li><b>was_http_list_installed_packages</b> - Execute IBM Installation Manager imcl commands listInstalledPackages -long, listInstalledPackages -verbose with output to files listinstalledpackages.hostname.out, listinstalledpackages.verbose.hostname.out in /tmp/output/was.</li>
<li><b>was_http_logs_check_errors</b> - To check for error, warning messages in WebSphere SystemOut.log, SystemError.log files and to check for error, warning messages in IBM HTTP Server error_log_*, http_plugin_log_* log files. Output to /tmp/output/was/was_http_logs_check_errors_hostname.out</li>
<li><b>was_http_stop_start</b> - Stop or start IBM HTTP Server and WebSphere.</li>
<li><b>was_syntax_processes_check</b> - Check syntax of file /etc/rc.was.config and number of entries for 2nd field userid in /etc/rc.was.config against number of java processes for same userid.</li>
</ul>
<p>See heading <b>Creation of Ansible Tower Job Templates with Survey</b> for above playbooks to be defined as Ansible Tower Job Templates with Survey. Playbook was_upgrade is required to be defined with Ansible Job Template containing Survey.</p>

<p>By default, Ansible playbooks run with a linear strategy, where all targeted endpoints run a task to completion before any endpoint starts on the next task, using the number of forks configured on the Tower Server to parallelize. Under the free strategy, an endpoint that is slow or stuck on a specific task won’t hold up the rest of the endpoints and/or tasks, unlike the situation with the default linear strategy. Above playbooks run with free strategy. </p>

<h2>Environments Tested</h2>
<ul>
<li>RedHat - Version 8.5 with WebSphere Network Deployment V9.0.5 installation of fixpack and interim fix</li>
<li>AIX - Version 7.2 TL5 SP1 with WebSphere Network Deployment V9.0.5 installation of fixpack and interim fix</li>
<li>Suse - To be tested</li>
</ul>

<h2>Provided WebSphere, HTTP Server Stop, Start Scripts</h2>

<p><b>Recommend to use provided WebSphere, HTTP Server stop, start scripts that are reliable with configuration files.</b> If existing Kyndyrl site stop, start scripts are used, see heading <b>Changes if Existing WebSphere, HTTP Server Stop, Start Scripts Used</b> for changes to perform.</p>
<p>The files documented below can be found at https://github.com/karthisai1118/WebSphere/tree/master/roles/was_http_stop_start/files</p>

<h3>HTTP Server</h3>
<p>Script rc.http with configuration file rc.http.config is used to stop and start HTTP Server.</p>
<p>Script rc.http is located in /etc for AIX and /usr/local/bin for Linux. Configuration file rc.http.config is located in /etc for AIX and Linux. Below is example of configuration file /etc/rc.http.config with path to stop and start HTTP server.</p>
<pre>
/opt9/IBM/IBMHttpServer/bin
/opt8/IBM/IBMHttpServer/bin
</pre>

<p>The following command will stop all HTTP Server processes in /etc/rc.http.config.</p>
<pre>
For AIX
/etc/rc.http stop

For Linux
/usr/local/bin/rc.http stop
</pre>

<p>The following command will start all HTTP Server processes in /etc/rc.http.config.</p>
<pre>
For AIX
/etc/rc.http start

For Linux
/usr/local/bin/rc.http start
</pre>

<p>Script rc.http has optional second parameter of path for lines in /etc/rc.http.config to stop or start. For example.</p>
<pre>
For AIX
/etc/rc.http stop /opt9/IBM/IBMHttpServer/bin
/etc/rc.http start /opt9/IBM/IBMHttpServer/bin

For Linux
/usr/local/bin/rc.http stop /opt9/IBM/IBMHttpServer/bin
/usr/local/bin/rc.http start /opt9/IBM/IBMHttpServer/bin
</pre>

<p>AIX has the following commands executed to setup the stop of HTTP Server at shutdown and start of HTTP Server at bootup.</p>
<pre>
cp rc.http /etc/rc.http
chown root:system /etc/rc.http
chmod 755 /etc/rc.http
cp rc.http.config /etc/rc.http.config
chown root:system /etc/rc.http.config
chmod 644 /etc/rc.http.config
</pre>

<p>AIX has the following /etc/inittab entry to start HTTP Server at bootup.</p>
<pre>
http:2:once:/etc/rc.http start > /var/log/was/rc.http.start.out 2>&1
</pre>

<p>AIX has the following in /etc/rc.shutdown to stop HTTP Server at shutdown.</p>
<pre>
/etc/rc.http stop > /var/log/was/rc.http.stop.out 2>&1
</pre>

<p>Linux has the following commands executed to setup the stop of HTTP Server at shutdown and start of HTTP Server at bootup.</p>
<pre>
cp rc.http /usr/local/bin/rc.http
chown root:root /usr/local/bin/rc.http
chmod 755 /usr/local/bin/rc.http
cp rc.http.config /etc/rc.http.config
chown root:root /etc/rc.http.config
chmod 644 /etc/rc.http.config
cp rc.http.service /etc/systemd/system/rc.http.service
chown root:root /etc/systemd/system/rc.http.service
chmod 644 /etc/systemd/system/rc.http.service
systemctl daemon-reload
systemctl enable rc.http
</pre>

<p>Update file /etc/rc.http.config with the HTTP Server processes running on the server. Command ps -ef|grep http can be executed to output HTTP Server processes</p>

<h3>WebSphere</h3>
<p>Script rc.was with configuration file rc.was.config is used to stop and start WebSphere processes of Deployment Manager, Node Agents and Application Servers.</p>

<p>Script rc.was is located in /etc for AIX and /usr/local/bin for Linux. Configuration file rc.was.config is located in /etc for AIX and Linux. Below is example of /etc/rc.was.config.</p>
<pre>
dmgr;was9;/opt9/IBM/WebSphere/AppServer/profiles/Dmgr01/bin;synch
nodeagent;was9;/opt9/IBM/WebSphere/AppServer/profiles/AppSrv01/bin;synch
appsrv;was9;/opt9/IBM/WebSphere/AppServer/profiles/AppSrv01/bin;synch;tiAuditLog
appsrv;was9;/opt9/IBM/WebSphere/AppServer/profiles/AppSrv01/bin;synch;aicstools
nodeagent;was8;/opt8/IBM/WebSphere/AppServer/profiles/AppSrv01/bin;synch
appsrv;was8;/opt8/IBM/WebSphere/AppServer/profiles/AppSrv01/bin;asynch;tisales1
appsrv;was8;/opt8/IBM/WebSphere/AppServer/profiles/AppSrv01/bin;asynch;tisales2
</pre>

<p>Fields below delimited by ;</p>
<ul>
<li>WebSphere process of dmgr for Deployment Manager, nodeagent for Node Agent and appsrv for Application Server.</li>
<li>Userid for WebSphere java process to run as.</li>
<li>Path with subdirectory bin for WebSphere process containing shell scripts to stop, start. Scripts are stopManager.sh, startManager.sh for dmgr and stopNode.sh, startNode.sh for nodeagent and stopServer.sh, startServer.sh for appsrv.</li>
<li>Start option of synch means to wait for start to complete and check return code.</li>
<li>Start option of asynch means to start in background with & and process next line of /etc/rc.was.config.  No check of return code. Can be used for high number of Application Servers to start on a server in parallel.</li>
<li>Profile name of Application Server when first field is appsrv.</li>
</ul>

<p>For parameter action of stop, the order of stop is Application Servers and then Node Agents and then Deployment Managers.</p>
<p>For parameter action of start, the order of start is Deployment Managers and then Node Agents and then Application Servers.</p>

<p>The following command will stop all Java processes in /etc/rc.was.config.</p>
<pre>
For AIX
/etc/rc.was stop

For Linux
/usr/local/bin/rc.was stop
</pre>

<p>The following command will start all Java processes in /etc/rc.was.config.</p>
<pre>
For AIX
/etc/rc.was start

For Linux
/usr/local/bin/rc.was start
</pre>

<p>Script rc.was has optional second parameter of userid for lines in /etc/rc.was.config with second field of userid to stop or start. For example.</p>
<pre>
For AIX
/etc/rc.was stop was9
/etc/rc.was start was9

For Linux
/usr/local/bin/rc.was stop was9
/usr/local/bin/rc.was start was9
</pre>

<p>AIX has the following commands executed to setup the stop of WebSphere at shutdown and start of WebSphere at bootup.</p>
<pre>
cp rc.was /etc/rc.was
chown root:system /etc/rc.was
chmod 755 /etc/rc.was
cp rc.was.config /etc/rc.was.config
chown root:system /etc/rc.was.config
chmod 644 /etc/rc.was.config
</pre>

<p>AIX has the following /etc/inittab entry to start WebSphere at bootup.</p>
<pre>
was:2:once:/etc/rc.was start > /var/log/was/rc.was.start.out 2>&1
</pre>

<p>AIX has the following in /etc/rc.shutdown to stop WebSphere at shutdown.</p>
<pre>
/etc/rc.was stop > /var/log/was/rc.was.stop.out 2>&1
</pre>

<p>Linux has the following commands executed to setup the stop of WebSphere at shutdown and start of WebSphere at bootup.</p>
<pre>
cp rc.was /usr/local/bin/rc.was
chown root:root /usr/local/bin/rc.was
chmod 755 /usr/local/bin/rc.was
cp rc.was.config /etc/rc.was.config
chown root:root /etc/rc.was.config
chmod 644 /etc/rc.was.config
cp rc.was.service /etc/systemd/system/rc.was.service
chown root:root /etc/systemd/system/rc.was.service
chmod 644 /etc/systemd/system/rc.was.service
systemctl daemon-reload
systemctl enable rc.was
</pre>

<p>Update file /etc/rc.was.config with the WebSphere processes running on the server. Command ps -ef|grep java can be executed to output WebSphere processes.</p>

<p>Setup the soap.client.props or sas.client.props or ssl.client.props file so that there is no prompt for userid and password during stop and start of WebSphere Deployment Manager, Application Server and Node Agent. Check the WebSphere Application Server Network Deployment documentation on how to setup.<p>

<h2>Creation of Ansible Tower Job Templates with Survey</h2>
<p>Ansible project with SCM TYPE of Git, SCM URL https://github.com/karthisai1118/WebSphere and SCM BRANCH/TAG/COMMIT of 1.0.6 will need to be defined.</p>

<p>Under heading <b>Playbooks</b> is list of playbooks contained in this project that you can define Ansible Tower job templates with survey. Playbook was_upgrade requires a job template with a survey. The other playbooks can be defined with a job template and survey if will be used.</p>
<p>https://github.com/karthisai1118/WebSphere/tree/master/roles can be opened in a web browser. Then click on a individual role. For each individual role, click on defaults and then click on main.yml to review which Ansible variable default value will require a survey prompt in the Ansible job template survey.</p> 
<p>Web link https://docs.ansible.com/ansible-tower/latest/html/userguide/job_templates.html documents how to create a job template with a survey. Add Survey Prompt input values can be copied from above Ansible roles default variables and comments in file main.yml.</p>
<p>Playbook was_upgrade imports roles filesystem_freespace, mount_unmount_software_repository_nfs, was_http_stop_start, was_upgrade, was_http_list_installed_packages, was_http_logs_check_errors to review default Ansible variables in each role to determine if a Survey Prompt should be defined to input a value to override default value.</p>
<p>Ansible job template with survey has no export, import function documented in https://access.redhat.com/solutions/3385441 with statement "Currently its not possible to export job templates to be consumed into another Ansible Tower instance". Below is survey added to required job template was_upgrade.</p>
<table style="width:100%" border="1">
 <tr>
   <th>PROMPT</th>
   <th>DESCRIPTION</th>
   <th>ANSIBLE VARIABLE NAME</th>
   <th>ANSWER TYPE</th>
   <th>MAXIMUM LENGTH CHOICE OPTIONS</th>
   <th>DEFAULT ANSWER</th>
 </tr>
 <tr>
   <td>Action_stop</td>
   <td>Stop WebSphere for /etc/rc.was.config entries and stop HTTP Server for /etc/rc.http.config entries containing parameter path_search value.</td>
   <td>action_stop</td>
   <td>Multiple Choice (single select)</td>
   <td>yes no</td>
   <td>yes</td>
 </tr>
 <tr>
   <td>Action_start</td>
   <td>Start WebSphere for /etc/rc.was.config entries and start HTTP Server for /etc/rc.http.config entries containing parameter path_search value. Additional condition to start WebSphere, HTTP Server if server variable action_start_was has value of yes.</td>
   <td>action_start</td>
   <td>Multiple Choice (single select)</td>
   <td>yes no</td>
   <td>yes</td>
 </tr>
 <tr>
   <td>File_cmds</td>
   <td>File name with extension of .cmds containing variables, imcl install commands stored in NFS mounted location. If WebSphere fix pack and interim fixes are being installed, add install statements for interim fixes after install statements for fix pack in this file. Also imcl uninstall and rollback statements.</td>
   <td>file_cmds</td>
   <td>Text</td>
   <td></td>
   <td>/mnt/WAS/cmds/filename.cmds</td>
 </tr>
 <tr>
   <td>Path_search</td>
   <td>Change input to opt9 for WebSphere V9, HTTP Server V9 or opt8 for WebSphere V8.5, HTTP Server V8.5. Do not use value with /. /etc/rc.was.config entries with third field for path and /etc/rc.http.config entries containing parameter path_search value will stop or start depending on parameters action_stop, action_start values.</td>
   <td>path_search</td>
   <td>Text</td>
   <td></td>
   <td>opt9</td>
 </tr>
 <tr>
   <td>Filesystem</td>
   <td>Filesystem for free space in MB check.</td>
   <td>filesystem</td>
   <td>Text</td>
   <td></td>
   <td>/opt9</td>
 </tr>
 <tr>
   <td>Filesystem_freespace_mb</td>
   <td>Check filesystem has free space in MB greater than value of variable filesystem_freespace_mb</td>
   <td>filesystem_freespace_mb</td>
   <td>Integer</td>
   <td></td>
   <td>512</td>
 </tr>
 <tr>
   <td>Group</td>
   <td>Group for chown -R userid:group /path_search/IBM/WebSphere/AppServer after imcl install commands executed. Userid from second field of /etc/rc.was.config with path containing variable path_search value.</td>
   <td>group</td>
   <td>Text</td>
   <td></td>
   <td>wasgroup</td>
 </tr>
 <tr>
   <td>Websphere installation directory</td>
   <td>Websphere installation directory without /patch_search/ at beginning to change ownership of /path_search/IBM/WebSphere/AppServer to userid:group</td>
   <td>websphere_install_dir</td>
   <td>Text</td>
   <td></td>
   <td>IBM/WebSphere/AppServer</td>
 </tr>
 <tr>
   <td>NFS server  IP address</td>
   <td>NFS server  IP address</td>
   <td>server_ipaddress</td>
   <td>Text</td>
   <td></td>
   <td>input_ip_address</td>
 </tr>
 <tr>
   <td>NFS server export path</td>
   <td>NFS server filesystem exported</td>
   <td>export_path</td>
   <td>Text</td>
   <td></td>
   <td>/software</td>
 </tr>
 <tr>
   <td>NFS client mointpoint</td>
   <td>NFS client mointpoint</td>
   <td>mountpoint</td>
   <td>Text</td>
   <td></td>
   <td>/mnt</td>
 </tr>
  <tr>
   <td>NFS_mount</td>
   <td>Mount NFS client mountpoint of /mnt.</td>
   <td>nfs_mount</td>
   <td>Multiple Choice (single select)</td>
   <td>yes no</td>
   <td>yes</td>
 </tr>
 <tr>
   <td>NFS_unmount</td>
   <td>Unmount NFS client mountpoint of /mnt.</td>
   <td>nfs_unmount</td>
   <td>Multiple Choice (single select)</td>
   <td>yes no</td>
   <td>yes</td>
 </tr>
 <tr>
   <td>Filesystem starts with for location of WebSphere, HTTP logs</td>
   <td>Filesystems that starts with for WebSphere, HTTP logs to search for error, warning messages.</td>
   <td>filesystem_starts_with</td>
   <td>Text</td>
   <td></td>
   <td>/logs</td>
 </tr>
 <tr>
   <td>Log_dir</td>
   <td>Location of redirected standard output, standard error messages log files. /was is appended for /var/log/ansible/was</td>
   <td>log_dir</td>
   <td>Text</td>
   <td></td>
   <td>/var/log/ansible</td>
 </tr>
</table>

<p>For ANSWER TYPE of Text, MINIMUM LENGTH of 1 and MAXIMUM LENGTH of 1024</p> 
<p>For ANSWER TYPE of Integer, MINIMUM LENGTH of 1 and MAXIMUM LENGTH of 100000</p> 


<h2>Perl Scripts to Generate IBM Installation Manager Commands</h2>
<p>Web link https://www.ibm.com/support/knowledgecenter/SSDV2W_1.8.5/com.ibm.cic.commandline.doc/topics/c_imcl_container.html documents the imcl commands like the following.</p>
<ul>
<li>imcl listInstalledPackages -long</li>
<li>imcl listAvailablePackages -repositories -long</li>
<li>imcl listAvailableFixes -repositories</li>
<li>imcl install</li>
</ul>
<p>Above commands are used by the following two Perl scripts to generate IBM Installation Manager imcl install commands.</p>
<p>Perl scripts was_fixpack_imcl_install_generate_cmds.pl, was_interim_fix_imcl_install_generate_cmds.pl documented below can be found at https://github.com/karthisai1118/WebSphere/tree/master/roles/was_upgrade/files</p>
<p>On AIX, execute Perl scripts was_fixpack_imcl_install_generate_cmds_aix.pl, was_interim_fix_imcl_install_generate_cmds_aix.pl for 64-bit Perl on AIX of /usr/bin/perl64 to prevent error message of opendir: Value too large to be stored in data type when NFS mounted.</p>
<p>Ansible Tower job template mount_unmount_nfs could be launched on first test WebSphere server to perform NFS mount. This first test WebSphere server represents a group of WebSphere servers with same packages and same installation directory locations from command imcl listInstalledPackages -long.</p>
<pre>
1. was_fixpack_imcl_install_generate_cmds.pl path_nfs
where parameter path_nfs is NFS mounted path where WebSphere fix pack and/or WebSphere V9 Java SDK are located.
Output message of:
File <b>/tmp/was_imcl_install_fixpack.cmds</b> contains imcl install commands for script was_imcl_install.sh to execute 
with first parameter of this file

Rename above file was_imcl_install_fixpack.cmds to add the WebSphere fixpack being installed. For example, add of 
was9fp11 for WebSphere V9 fixpack 11.
mv /tmp/was_imcl_install_fixpack.cmds /tmp/was_imcl_install_fixpack_was9fp11.cmds

Below shows subdirectories created with downloaded files extracted for a WebSphere Network Deployment V9 Fix Pack 11 
and Java packages in NFS server filesystem /software that is exported for NFS mounts.
/software/was/WAS9FP11
ls
ihsplugin  java  was  wct
</pre>

<pre>
2. was_interim_fix_imcl_install_generate_cmds.pl path_nfs
where parameter path_nfs is NFS mounted path where WebSphere interim fix(s) are located.
Output message of:
File <b>/tmp/was_imcl_install_interim_fix.cmds</b> contains imcl install commands for script was_imcl_install.sh to execute 
with first parameter of this file

If interim fix(s) are being installed after a fixpack installation, then create one combined cmds file with the 
interim fix(s) install commands after the fixpack install commands. For example.
mv /tmp/was_imcl_install_fixpack_was9fp11.cmds /tmp/was_imcl_install_fixpack_was9fp11_interim_fix.cmds
cat /tmp/was_imcl_install_interim_fix.cmds>>/tmp/was_imcl_install_fixpack_was9fp11_interim_fix.cmds

Below shows subdirectory created for a interim fix in NFS server filesystem /software that is exported for NFS mounts. 
Additional interim fixes can be downloaded and extracted into a subdirectory for each interim fix.
/software/was/WAS9FP11_ifix
ls
PH11655

Execute command like example below after download, extraction of WebSphere fixpack and interim fix(s) has be done 
for WebSphere server with NFS mount to have permissions to read, execute.
chmod -R 755 /software/was
</pre>
<p>Perl script was_interim_fix_imcl_install_generate_cmds.pl is executed on a WebSphere server where the WebSphere fix pack has been installed that the WebSphere interim fix(s) require.</p>
<p>Copy the final cmds file of IBM Installation Manager install commands into NFS server filesystem that is exported. For example /software/was/cmds/was_imcl_install_fixpack_was9fp11_interim_fix.cmds. Fom this example, the Ansible variable file_cmds value is /mnt/was/cmds/was_imcl_install_fixpack_was9fp11_interim_fix.cmds for where cmds file of IBM Installation Manager install commands is found from NFS mount.</p>

<h2>Changes if Existing WebSphere, HTTP Server Stop, Start Scripts Used</h2>
<p>Provided stop, start scripts rc.was, rc.http and configuration files rc.was.config, rc.http.config are not used.</p>
<p>Perform the following updates if previous local site scripts to stop and start IBM HTTP Server and WebSphere are used.</p>
<ul>
<li>Update script was_http_stop_start.sh to execute local site stop, start scripts for IBM HTTP Server, WebSphere instead of provided rc.http, rc.was scripts. Test updated script was_http_stop_start.sh.</li>
<li>Uncomment and specify value for default variable userid in role was_upgrade.</li>
<li>Create Ansible Tower Job Template with Survey using playbook file was_upgrade2.yml. Also create a Survey prompt for Ansible variable name userid in Ansible Tower Job Template for playbook was_upgrade2.yml</li>
</ul>

<p>The Continuous-Engineering Git repository at https://github.com/karthisai1118/WebSphere is read-only for multiple Kyndryl sites to use. To perform the above updates you need to clone this Git repository into your local Kyndryl site's Git repository. Below has instructions on how to perform.</p>

<p>Web link https://help.ocean.ibm.com/help/ui/#/article/github_ent_kyndryl/github_overview to read on how to create a GitHub organization for your Kyndryl organization and create a Git repository in your GitHub organization.</p>

<p>Make sure that the repository is created with Owner of your organization with the following inputs.</p>
<ul>
<li>Input Repository name of ansible-role-websphere-upgrade-local
<li>Input Description of Clone repository ansible-role-websphere-upgrade to ansible-role-websphere-upgrade-local for local modifications. 
<li>Select Private 
</ul>

<p>Copy and save the the web link with https://github.com/karthisai1118/WebSphere.local.git where organization is your Kyndryl organization.</p>

<p>From https://github.kyndryl.net/settings/tokens, create a personal access tokens with Generate new token. Tokens you have generated are used to access the GitHub API for git commands. Make sure to copy your new personal access token now. You won't be able to see it again. You could save the generated personal access token in https://1password.com/kyndryl</p>

<p>Click on Git Bash and execute commands below.</p>
<ul>
<li>mkdir /c/Ansible</li>
<li>mkdir /c/Ansible/projects</li>
<li>cd /c/Ansible/projects</li>
<li>git clone https://github.com/karthisai1118/WebSphere-local</li>
<li>cd /c/Ansible/projects/WebSphere-local</li>
<li>ls to display playbook *.yml files and subdirectory roles</li>
</ul>

<p>Execution of Git Bash command <b>git remote -v</b> will show the Continuous-Engineering Git repository below. This needs to be updated to your Kyndryl organization ansible-role-websphere-upgrade-local.</p>
<pre>
origin  https://github.com/karthisai1118/WebSphere.git (fetch)
origin  https://github.com/karthisai1118/WebSphere.git (push)
</pre>

<p>Execute the following Git Bash command to set url to your Kyndryl organization Git repository ansible-role-websphere-upgrade-local.</p>
git remote set-url origin https://github.com/karthisai1118/WebSphere-local.git

<p>Execution of Git Bash command <b>git remote -v</b> will show your Kyndyrl organization ansible-role-websphere-upgrade-local below.</p>
<pre>
origin  https://github.com/karthisai1118/WebSphere-local.git (fetch)
origin  https://github.com/karthisai1118/WebSphere-local.git (push)
</pre>

<p>Perform the following local modifications.</p>
<pre>
cd /c/Ansible/projects/ansible-role-websphere-upgrade-local/roles/was_http_stop_start/files
Copy file was_http_stop_start.sh to another location. Update the copy of this file to use your local stop, start 
scripts for IBM HTTP Server and WebSphere and test that stop, start is successful.
Copy updated, tested file was_http_stop_start.sh to 
/c/Ansible/projects/websphere-local/roles/was_http_stop_start/files

cd /c/Ansible/projects/websphere-local/roles/was_upgrade/defaults
Edit file main.yml
Uncomment line below and update value to userid
#userid: wasn
For example
userid: was9

Update the Ansible variable group value.
group: wasgroup
</pre>

<p>Click on Git Bash and execute commands below.</p>
<ul>
<li>cd /c/Ansible/projects/websphere-local</li>
<li>git add /c/Ansible/projects/websphere-local/roles/was_http_stop_start/files/was_http_stop_start.sh</li>
<li>git add /c/Ansible/projects/websphere-local/roles/was_upgrade/defaults/main.yml</li>
<li>git commit -m 'Local changes to files was_http_stop_start.sh and defaults/main.yml for role was_upgrade'</li>
<li>git push -u origin master</li>
</ul>

<p>From web link https://github.com/karthisai1118/WebSphere-local.git, verify that the above local modifications for files was_http_stop_start.sh, main.yml show.</p>

<p>Update Ansible Tower project for WebSphere Upgrade to SCM URL to https://github.com/karthisai1118/WebSphere-local.git where organization is your Kyndryl organization. Click the icon for Ansible Tower project for WebSphere Upgrade to Get latest SCM revision.</p>

<p>Update Ansible Tower Job Template for WebSphere Upgrade for playbook was_upgrade2.yml. Also create a Survey prompt for Ansible variable name userid in Ansible Tower Job Template for playbook was_upgrade2.yml.</p>

<h2>Author Information</h2>
Karthisai




