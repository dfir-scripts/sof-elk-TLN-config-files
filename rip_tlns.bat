@echo off
setlocal
Set reg_path=
echo Enter Full Path to Registry Files:
Set /P reg_path=
Set comp_name=
echo (Optional) Enter Computer Name, Host Name or IP Address:
Set /P comp_name=
if defined %comp_name% (comp_name="-s %comp_name%")
Set user_name=
echo (Optional) Enter User Name:
Set /P user_name=
if defined %user_name% (user_name="-u %user_name%")

echo Searhing for Registry files in %reg_path%...
echo Standby...
dir "%reg_path%" /s /b /a-d |findstr /I /r "\\system$ \\software$ \\security$ \\sam$ amcache.hve$" >reghives.txt
type NUL > regripper.all.tln
if exist reghives.txt (echo Registry hives found in "%reg_path%")
type reghives.txt
dir "%reg_path%" /s /b /a-d |findstr /I /r "\\ntuser.dat$ \\usrclass.dat$" > ntuserhives.txt 
if exist ntuserhives.txt (echo Registry hives found in "%reg_path%")
type ntuserhives.txt
for /f %%I in (reghives.txt) do rip.exe -s "%comp_name%" -u "%user_name%" -aT -r "%%I" >> regripper.all.tln
for /f %%I in (ntuserhives.txt) do rip.exe -s "%comp_name%" -u "%user_name%" -aT -r "%%I" >> regripper.all.tln
type regripper.all.tln |sort /UNIQ |findstr /r "^[1,0]" > regripper.sorted.tln
