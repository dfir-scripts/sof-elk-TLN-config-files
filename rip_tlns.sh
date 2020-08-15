#!/bin/bash
#https://github.com/keydet89/regripper2.8
#        rip_tln_plugins.sh

# basic script usage requires input path 
function usage() {
  echo -e "
USAGE:
rip_tlns.sh -p [Input Path] -c -s -a [computer name] -u [user name]

    - p [Input Path] Root dir of registry files
        mounted image or file export

   OPTIONAL:
   -c Outputs CSV with readable timestamps
   -s Set the server name field on unset values
   -u Set user name on empty values
   -a all tln plugins (del_tln, slack_tln, regtime_tln)

    "
  1>&2; exit 1;
}

# Run Regripper "compname" plugin to identify the computer name
function get_computer_name(){
   [ "$comp_name" == "" ] &&  \
   comp_name=$(find $reg_dir -type f  2>/dev/null|egrep -m1 -i /system$| while read d;
     do 
       rip.pl -r "$d" -p compname 2>/dev/null |grep -i "computername   "|awk -F'= ' '{ print $2 }';done)
}

#Run RegRipper on SOFTWARE Hive
function regrip_software(){
find $reg_dir -type f | grep -i "software$" |while read rpath;
  do
    for software_plugin in "${software_tln_plugins[@]}";
    do
      rip.pl -r "$rpath" -p "$software_plugin" |sed "s/|||/|${comp_name}|${user_name}|/" >> $tempfile
      [ "$all" != "" ] && \
      for all_plugin in "${all_tln_plugins[@]}";
      do
        rip.pl -r "$rpath" -p "$all_plugin" >> $tempfile
      done
    done
  done
}

#Run RegRipper on SYSTEM Hive
function regrip_system(){
find $reg_dir -type f | grep -i "system$" |while read rpath;
  do
    for system_plugin in "${system_tln_plugins[@]}";
    do
      rip.pl -r "$rpath" -p "$system_plugin" |sed "s/|||/|${comp_name}|${user_name}|/" >> $tempfile
      [ "$all" != "" ] && \
      for all_plugin in "${all_tln_plugins[@]}";
      do
        rip.pl -r "$rpath" -p "$all_plugin" >> $tempfile
      done
    done
  done
}

#Run RegRipper on SECURITY Hive
function regrip_security(){
find $reg_dir -type f | grep -i "security$" |while read rpath;
  do
    for security_plugin in "${security_tln_plugins[@]}";
    do
      rip.pl -r "$rpath" -p "$security_plugin" |sed "s/|||/|${comp_name}|${user_name}|/" >> $tempfile
      [ "$all" != "" ] && \
      for all_plugin in "${all_tln_plugins[@]}";
      do
        rip.pl -r "$rpath" -p "$all_plugin" >> $tempfile
      done
    done
  done
}
#Run RegRipper on SAM Hive
function regrip_sam(){
find $reg_dir -type f | grep -i "sam$" |while read rpath;
  do
    for sam_plugin in "${sam_tln_plugins[@]}";
    do
      rip.pl -r "$rpath" -p "$sam_plugin" |sed "s/|||/|${comp_name}|${user_name}|/" >> $tempfile
      [ "$all" != "" ] && \
      for all_plugin in "${all_tln_plugins[@]}";
      do
        rip.pl -r "$rpath" -p "$all_plugin" >> $tempfile
      done
    done
  done
}


#Run Reripper on NTUSER.DAT and USRCLASS.DAT files
function regrip_users_dir(){
find "$users_dir" -maxdepth 2 ! -type l|grep -i ntuser.dat$ |while read ntuser_path;
do
  usrclass_file=$(find "$users_dir"/"$user_name"/[aA]*[aA]/[lL]*[lL]/[mM][iI]*[tT]/[wW]*[sS] -maxdepth 1 -type f 2>/dev/null|grep -i -m1 "\/usrclass.dat$")
  user_name=$( echo "$ntuser_path"|sed 's/\/$//'|awk -F"/" '{print $(NF-1)}')
  for ntuser_plugin in "${ntuser_tln_plugins[@]}";
  do
    rip.pl -r "$ntuser_path" -p "$ntuser_plugin" |sed "s/|||/|${comp_name}|${user_name}|/" >> $tempfile
  done
  for usrclass_plugin in "${usrclass_tln_plugins[@]}";
  do
    rip.pl -r "$usrclass_file" -p "$usrclass_plugin" >> $tempfile
  done
  [ "$all" != "" ] && \
  for all_plugin in "${all_tln_plugins[@]}";
  do
    rip.pl -r "$usrclass_file" -p "$all_plugin" >> $tempfile
  done
done
}

#Run RegRipper on AmCache.hve
function regrip_amcache.hve(){
for amcache_plugin in "${amcache_tln_plugins[@]}";
do
  rip.pl -r "$amcache_file" -p "$amcache_plugin" |sed "s/|||/|${comp_name}|${user_name}|/" >> $tempfile
  [ "$all" != "" ] && \
  for all_plugin in "${all_tln_plugins[@]}";
  do
    rip.pl -r "$amcache_file" -p "$all_plugin" >> $tempfile
  done
done
}

#Run Regripper on SysCache.hve
function regrip_syscache.hve(){
for syscache_plugin in "${syscache_tln_plugins[@]}";
do
  rip.pl -r "$syscache_file" -p "$syscache_plugin" >> $tempfile
  [ "$all" != "" ] && \
  for all_plugin in "${all_tln_plugins[@]}";
  do
    rip.pl -r "$syscache_file" -p "$all_plugin" >> $tempfile
  done
done
}

#List of registry files
#reg_files="software system sam security usrclass.dat amcache.hve syscache.hve ntuser.dat"
#reg_files="software system sam security"
#Regripper tln_plugins
#reg_plugin_groups=("software_tln_plugins" "system_tln_plugins" "security_tln_plugins" "sam_tln_plugin" )
#ntuser tln plugin names
ntuser_tln_plugins=("appkeys_tln" "applets_tln" "attachmgr_tln" "cached_tln" "cmdproc_tln" "gpohist_tln" "mixer_tln" "mmc_tln" "mndmru_tln" "muicache_tln" "officedocs2010_tln" "osversion_tln" "recentapps_tln" "runmru_tln" "recentdocs_tln" "sysinternals_tln" "trustrecords_tln" "tsclient_tln" "typedpaths_tln" "typedurlstime_tln" "typedurls_tln" "urun_tln" "winrar_tln" "uninstall_tln" "userassist_tln")
#software tln plugin names
software_tln_plugins=("appkeys_tln" "apppaths_tln" "at_tln" "cmd_shell_tln" "direct_tln" "landesk_tln" "logmein_tln" "networklist_tln" "silentprocessexit_tln" "srun_tln" "tracing_tln" "winlogon_tln" "uninstall_tln")
#system tln plugin names
system_tln_plugins=("appcompatcache_tln" "bam_tln" "bthport_tln" "legacy_tln" "shimcache_tln" "svc_tln" "shellbags_tln")
#security  tln plugin names
security_tln_plugins="secrets_tln"
#sam tln plugin names
sam_tln_plugin="samparse_tln"
#usrclass
usrclass_tln_plugins=("shellbags_tln" "muicache_tln")
#amcache tln plugin names
amcache_tln_plugins="amcache_tln"
#syscache tln plugin names
syscache_tln_plugins="syscache_tln"
#Plugins which can be run on all registry files
#clsid_tln output is a software plugin that extracts file associations.  It is categorized as "all_tln" because of the time needed to execute and the size of output 
all_tln_plugins=("clsid_tln"  "del_tln" "regtime_tln" "slack_tln")


#Setup command line parameters (see usage)
while getopts "hcap:s:u:" opt; do
  case $opt in
    c) csv="yes";;
    p) input_path="$OPTARG";;
    s) comp_name="$OPTARG";;
    u) user_name="$OPTARG";;
    a) all="yes":;;
    h|*) usage ;;
  esac
done

# Verify command syntax
[ "$input_path" == "" ] && usage && echo -e "Make sure registry files have a valid path (i.e. Windows\System32\Config, Users,etc)"
# Find and set paths for registry files
reg_dir=$(find "$input_path"/[wW]*[sS]/[Ss]*32/[cC][oO]*[gG] -maxdepth 0 -type d 2>/dev/null)
users_dir=$(find "$input_path"/[uU][sS][eE][rR][sS] -maxdepth 0 -type d 2>/dev/null)
amcache_file=$(find "$input_path"/[wW]*[sS]/[aA][pP]*[aA][tT]/Programs/ -maxdepth 1 -type f 2>/dev/null |grep -i -m1 "\/amcache.hve$" )
syscache_file=$(find "$input_path" -maxdepth 0 -type f 2>/dev/null|grep -i -m1 "System\ Volume\ Information\syscache.hve$" )

# Begin by finding the computer name
[ "$comp_name" == "" ] && get_computer_name
#cleanup and create a new new temp file
rm /tmp/$comp_name.* 2>/dev/null
tempfile=$(mktemp /tmp/$comp_name.XXXXXXXX)
# Run regripper on each registry file type and write to temp file
regrip_software
regrip_system
regrip_security
regrip_sam
[ -d "$users_dir" ] && regrip_users_dir
regrip_amcache.hve
regrip_syscache.hve
# Validate, sort, reduce, format and print TLN to stdout
[ -f "$tempfile" ] && \
[ "$csv" == "" ] && cat $tempfile | grep -Ea "^[0-9]{10}\||^0\|" | grep -va "|$" |grep "|" |sort -r |uniq ||
  cat $tempfile | grep -Ea "^[0-9]{10}\||^0\|" | grep -va "|$" | \
  awk -F'|' '{$1=strftime("%Y-%m-%d %H:%M:%S",$1)}{print $1","$2","$3","$4","$5}'|sort -r |uniq 
