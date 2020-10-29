#!/bin/bash
ltime=`date "+%Y-%m-%d %H:%M:%S"`
utc_time=`date -u "+%Y-%m-%dT%H:%M:%S.%NZ"|cut -b  1-23,30`
expect_node=`sshpass -p ChangeMe ssh admin@55.13.116.23 getrackinfo  |sed  '1,3d'|sed '9,$d'|awk '{print $5}'|sed -n "8p"`
#install sshpass 
yum install sshpass -y 2>&1 > /dev/null
#getrackinfo
echo -en "\033[47;30m$ltime\t\t###getrackinfo\033[0m\n"
sshpass -p ChangeMe ssh  admin@55.13.116.23 getrackinfo  |sed  '1,3d'|sed '9,$d'| awk '{print "\tis_slave:"$3,"\tnode_ip:"$5}'

#check_port
echo -en "\n\033[47;30m$ltime\t\t###check port\033[0m\n"
for i in `ssh admin@55.13.116.23 getrackinfo  |sed  '1,3d'|sed '9,$d'| awk '{print $5}'`
do
  echo -e "\n$ltime\t------Check Port (22,9020) $i------"
  sshpass -p ChangeMe ssh  admin@$i  netstat -ntlp 2>&1 |grep -E ":9020|:22"
  tcp_listen=`sshpass -p ChangeMe ssh  admin@$i netstat -ntlp 2>&1|grep -E ":9020|:22"|wc -l 2>&1`
  if [ $tcp_listen -gt 2 ]
  then 
     echo -e "\n\033[32m\t9020 22 Port OK...\033[0m"
     echo '{"level":"info","is_alive":"1","node_ip":"'$i'","time":"'$utc_time'"}'  >> /tmp/tcp_check_port.txt 
  else
     echo  -e "\n\033[31m\tError... 9020 Or 22 Port down\033[0m"
     echo  '{"level":"info","is_alive":"0","node_ip":"'$i'","time":"'$utc_time'"}'  >> /tmp/tcp_check_port.txt
     exit
  fi
done

# request_bucket_query
echo -en "\n\033[47;30m$ltime\t\t###request_bucket_query check\033[0m\n"
query_result=`sshpass -p ChangeMe ssh  admin@$expect_node  svc_log -f ERROR.*REQUEST_BUCKET_QUERY -sr resourcesvc -start 1h`
if test "$query_result"
then
   echo -e "\033[31m\tError... $query_result \033[0m"
else
   echo  -e "\033[32m\tOK...\033[0m"
fi

#svc_dt check
echo  -en "\n\033[47;30m$ltime\t\t###svc_dt check\033[0m\n" 
dt_source=`sshpass -p ChangeMe ssh  admin@$expect_node svc_dt check -l`
dt_result=`sshpass -p ChangeMe ssh  admin@$expect_node svc_dt check -l 2>&1| grep -v "Total" | grep "Unready" | awk {'print $NF'}`
echo -e "$dt_source\n"
if  test -n "$dt_source"
then 
  if [ "$dt_result" != 0 ]
  then
    echo -e "\033[31m\tError...  $dt_result \033[0m" 
  else
    echo -e "\033[32m\tOK...\033[0m"
  fi
else
  echo -e "\033[31m\tError...No output\033[0m"
fi

#svc_dt  events -sr resourcesvc -start '1 day ago'
echo -en "\n\033[47;30m$ltime\t\t###svc_dt event\033[0m\n"
event_source=`sshpass -p ChangeMe ssh  admin@$expect_node svc_dt events -sr resourcesvc -start "'1 day ago'"`
event_result=`sshpass -p ChangeMe ssh  admin@$expect_node svc_dt events -sr resourcesvc -start "'1 day ago'" 2>&1 | grep -i "error"`
echo -e "$event_source\n"
if test -n "$event_source"
then
  if test $event_result
  then
    echo -e "\033[31m\tError... $event_result \033[0m" 
  else
    echo -e "\033[32m\tOK...\033[0m"
  fi
else
  echo -e "\033[31m\tError...No output\033[0m"
fi


#viprexec fcli maintenance list 
echo -en "\n\033[47;30m$ltime\t\t###maintenance_mode check\033[0m\n"
maintenance_source=`sshpass -p ChangeMe ssh  admin@$expect_node viprexec fcli maintenance list`
maintenance_result=`sshpass -p ChangeMe ssh  admin@$expect_node viprexec fcli maintenance list 2>&1 | awk {'print $NF'} | grep -vE "MODE|ACTIVE|169"`
echo -e "$maintenance_source\n"
if test -n "$maintenance_source"
then
  if test $maintenance_result
  then
    echo -e "\033[31m\tError... $maintenance_result \033[0m" 
  else
    echo -e "\033[32m\tOK...\033[0m"
  fi
else
  echo -e "\033[31m Error...No output\033[0m\n"
fi


# doit uptime
echo  -en "\n\033[47;30m$ltime\t\t###doit uptime check\033[0m\n"
uptime_source=`sshpass -p ChangeMe ssh  admin@$expect_node doit uptime`
uptime_result=`sshpass -p ChangeMe ssh  admin@$expect_node doit uptime | awk {'print $NF'} | grep -vE "ssh|login|pts" | sort -r | head -1` 
echo -e "$uptime_source\n"
if test -n "$uptime_source"
then
  if [ X$uptime_result == X ] || [ $uptime_result -gt 24 ]
  then
    echo  -e "\033[31m\tError... Current Load $uptime_result...... \033[0m"
  else
    echo  -e "\033[32m\tOK...\033[0m"
  fi
else
  echo -e "\033[31m\tError...No output\033[0m"
fi


# svc_perf gcstall -sr vnest 
echo  -en "\n\033[47;30m$ltime\t\t###vnest check\033[0m\n"
gcstall_source=`sshpass -p ChangeMe ssh  admin@$expect_node svc_perf gcstall -sr vnest 2>&1 |grep -v  "line 300"`
echo -en "\n$gcstall_source\n"
sshpass -p ChangeMe ssh  admin@$expect_node   svc_perf gcstall -sr vnest 2>&1 | awk {'print $7'} | grep "%" | sort -u -r | head -1  > /tmp/vnest_result.txt
sed -i 's/'%'//g' /tmp/vnest_result.txt
stopped_num=`cat /tmp/vnest_result.txt` 

if test -n "$gcstall_source"
then
  if [ X$stopped_num == X ] || [ $stopped_num -gt 10 ]
  then
    echo  -e "\033[31m\tError... Current Stopped time $stopped_num \033[0m"
  else
    echo  -e "\033[32m\tOK...\033[0m"
  fi
else
  echo -e "\n\033[31m\tError...No output\033[0m\n"
fi


# svc_perf gcstall -sr resourcesvc
echo  -en "\n\033[47;30m$ltime\t\t###resourcesvc check\033[0m\n"
resource_source=`sshpass -p ChangeMe ssh  admin@$expect_node  svc_perf gcstall -sr resourcesvc 2>&1 |grep -v  "line 300"`
echo -e "$resource_source\n"
sshpass -p ChangeMe ssh  admin@$expect_node svc_perf gcstall -sr resourcesvc 2>&1 |awk {'print $7'} | grep "%" | sort -u -r | head -1 > /tmp/resource_result.txt
sed -i 's/'%'//g' /tmp/resource_result.txt
resource_num=`cat /tmp/resource_result.txt`

if test -n "$resource_source"
then
  if [ X$resource_num == X ] || [ $resource_num -gt 10 ]
  then
    echo  -e "\033[31m\tError... Current Stopped time $resource_num \033[0m"
  else
    echo  -e "\033[32m\tOK...\033[0m"
  fi
else
  echo -e "\033[31m\tError...No output\033[0m"
fi


#  svc_perf gcstall -sr cm
echo  -en "\n\033[47;30m$ltime\t\t###cm check\033[0m\n"
cm_source=`sshpass -p ChangeMe ssh  admin@$expect_node svc_perf gcstall -sr cm 2>&1 |grep -v  "line 300"`
echo -e "$cm_source\n"
sshpass -p ChangeMe ssh  admin@$expect_node svc_perf gcstall -sr cm 2>&1 |awk {'print $7'} | grep "%" | sort -u -r | head -1 > /tmp/cm_result.txt
sed -i 's/'%'//g' /tmp/cm_result.txt
cm_num=`cat /tmp/cm_result.txt`
if test -n "$cm_source"
then
  if [ X$cm_num == X ] || [ $cm_num -gt 10 ]
  then
    echo  -e "\033[31m\tError... Current Stopped time $cm_num \033[0m"
  else
    echo  -e "\033[32m\tOK...\033[0m"
  fi
else
  echo -e "\n\033[31m\tError...No output\033[0m\n"
fi


#svc_perf gcstall -sr blobsvc
echo  -en "\n\033[47;30m$ltime\t\t###blobsvc check\033[0m\n"
blobsvc_source=`sshpass -p ChangeMe ssh  admin@$expect_node svc_perf gcstall -sr  blobsvc 2>&1 |grep -v  "line 300"`
echo -e "$blobsvc_source\n"
sshpass -p ChangeMe ssh  admin@$expect_node svc_perf gcstall -sr  blobsvc 2>&1 | awk {'print $7'} | grep "%" | sort -u -r | head -1 > /tmp/blobsvc_result.txt
sed -i 's/'%'//g' /tmp/blobsvc_result.txt
blobsvc_num=`cat /tmp/blobsvc_result.txt`
if test -n "$blobsvc_source"
then
  if [ X$blobsvc_num == X ] || [ $blobsvc_num -gt 10 ]
  then
    echo  -e "\033[31m\tError... Current Stopped time $blobsvc_num \033[0m"
  else
    echo  -e "\033[32m\tOK...\033[0m"
  fi
else
  echo -e "\n\033[31m\tError...No output\033[0m\n"
fi

#sudo xdoctor 
echo -e "\033[47;30m$ltime\t\t------xdoctor check------\033[0m\n"
xdoctor_source=`sshpass -p ChangeMe ssh  admin@$expect_node sudo xdoctor`
xdoctor_null=`sshpass -p ChangeMe ssh  admin@$expect_node sudo xdoctor|head -1`
echo -e "$xdoctor_source\n"
xdoctor_result=`sshpass -p ChangeMe ssh  admin@$expect_node sudo xdoctor 2>&1|grep -i "error"|grep -vE "Remote Service|Number of ERROR"`
if test  -n "$xdoctor_null"
then
  if test $xdoctor_result; then
     echo -e "\n\033[31m Error... $xdoctor_result \033\n"
  else
     echo -e "\n\033[32m OK...\033[0m\n"
  fi
else

#DNS health check
echo -en "\n\033[47;30m$ltime\t\t###dns server check\033[0m\n"
#sshpass -p ChangeMe ssh  admin@$expect_node `awk '{if($1=="nameserver" && length($2) <= 16 ){print $2}}' /etc/resolv.conf ` |  while read line
sshpass -p ChangeMe ssh  admin@$expect_node cat /etc/resolv.conf |grep "nameserver"|awk '{print $2}'  |  while read line
do
  if  echo "" | timeout --signal=9 5 telnet $line 53 2>&1 | grep -i connected > /tmp/dnscheck.log
  then
    echo  -e "\033[32m\tDNS $line OK\033[0m"
  else
    echo  -e "\033[31m\tError... Current Unready DNS $line \033[0m"
  fi
done

# NTP health check
#sshpass -p ChangeMe ssh  admin@$expect_node sudo awk '{if($1=="server"){print $2}}' /etc/ntp.conf | while read line
echo -en "\n\033[47;30m$ltime\t\t###ntp server check\033[0m\n"
sshpass -p ChangeMe ssh  admin@$expect_node sudo cat  /etc/ntp.conf | grep  "iburst"|awk '{print $2}' | while read line
do
  #if echo "" | timeout --signal=9 8 telnet $line 123 2>&1 | grep -i connected > /tmp/ntpcheck.log
  #if nc -i 4 -uv $line 123 2>&1 | grep -i connected > /tmp/ntpcheck.log
  if ntpdate -q $line > /tmp/ntpcheck.log 2>&1
  then
    echo  -e "\033[32m\tNTP $line OK\033[0m"
  else
    echo  -e "\033[31m\tError... Current Unready NTP $line \033[0m"
  fi
done
echo " "
