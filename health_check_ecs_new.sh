#!/bin/bash
ltime=`date "+%Y-%m-%d %H:%M:%S"`
utc_time=`date -u "+%Y-%m-%dT%H:%M:%S.%NZ"|cut -b  1-23,30`
node_ip=(55.13.116.23 55.13.116.24 55.13.116.25 55.13.116.26 55.13.116.27 55.13.116.28 55.13.116.29 55.13.116.30)
password="ChangeMe"
#install sshpass
#yum install sshpass -y 2>&1 > /dev/null

#mkdir logs dir
if [ ! -d "/tmp/ecs" ];then
  mkdir -p  /tmp/ecs
fi

#check node port
echo -e "\033[47;30m$ltime###check port\033[0m\n"
for i in ${node_ip[*]}
do
  if  timeout --signal=9 5 telnet $i 22  2>&1 | grep -i connected >> /tmp/check_port.log  && timeout --signal=9 5 telnet $i 9020  2>&1 | grep -i connected >> /tmp/ecs/check_port.log
  then
    echo -e "\033[32m\t$i 9020 22 Port OK...\033[0m"
    echo '{"level":"info","is_alive":"1","node_ip":"'$i'","time":"'$utc_time'"}'  >> /tmp/tcp_check_port.txt
    echo $i > /tmp/ecs/node_iplist.txt
  else
    echo  -e "\033[31m\t$i\tError...9020 Or 22 Port down\033[0m"
    echo  '{"level":"info","is_alive":"0","node_ip":"'$i'","time":"'$utc_time'"}'  >> /tmp/tcp_check_port.txt
  fi
done

#expect node 
expect_node=`cat /tmp/ecs/node_iplist.txt|awk 'END{print}'`

# request_bucket_query
echo -en "\n\033[47;30m$ltime###request_bucket_query check\033[0m\n"
sshpass -p $password  ssh  admin@$expect_node  svc_log -f ERROR.*REQUEST_BUCKET_QUERY -sr resourcesvc -start 1h 2>/tmp/ecs/query_result.txt
if [ $? -eq 0 ];then 
  query_result=`cat /tmp/ecs/query_result.txt |grep -i "error"|grep -v "Filter"`
  if [ -n $query_result ];then 
    echo -e "\033[32m\tOK...\033[0m"
  else
    echo -e "\033[31m\tError...\033[0m"
  fi
else
  echo -e "\033[31m\tCommand Error...\033[0m"
fi

#svc_dt check
echo  -en "\n\033[47;30m$ltime###svc_dt check\033[0m\n" 
sshpass -p ChangeMe ssh  admin@$expect_node svc_dt check -l 2>&1| grep -v "Total" | grep "Unready" | awk {'print $NF'} > /tmp/dt_result.txt
if [ $? -eq 0 -a -s /tmp/dt_result.txt -a $(cat /tmp/dt_result.txt) -ne 0 ];then
  echo -e "\033[31m\tError...`cat /tmp/dt_result.txt` \033[0m" 
else
  echo -e "\033[32m\tOK...\033[0m"
fi

#svc_dt  events -sr resourcesvc -start '1 day ago'
echo -en "\n\033[47;30m$ltime###svc_dt event\033[0m\n"
sshpass -p ChangeMe ssh  admin@$expect_node svc_dt events -sr resourcesvc -start "'1 day ago'" 2>&1 | grep -i "error" >  /tmp/event_result.txt
#if [ "$?" -eq 0 ];then
  if test "$(cat /tmp/event_result.txt)";then
    echo -e "\033[31m\tError...\033[0m"
  else
    echo  -e "\033[32m\tOK...\033[0m"
  fi
#fi

##viprexec fcli maintenance list 
echo -en "\n\033[47;30m$ltime###maintenance_mode check\033[0m\n"
sshpass -p ChangeMe ssh  admin@$expect_node viprexec fcli maintenance list 2>&1 | awk {'print $NF'} | grep -vE "MODE|ACTIVE|169" > /tmp/maintenance.txt
if  [ $? -eq 0 -a -s /tmp/dt_result.txt -a -n "$(cat /tmp/maintenance.txt)" ];then
    echo -e "\033[31m\tError... $maintenance_result \033[0m" 
else
    echo -e "\033[32m\tOK...\033[0m"
fi

# doit uptime
echo  -en "\n\033[47;30m$ltime###doit uptime check\033[0m\n"
sshpass -p ChangeMe ssh  admin@$expect_node doit uptime | awk {'print $NF'} | grep -vE "ssh|login|pts" | sort -r | head -1 > /tmp/uptime.txt
if [ $? -eq 0 -a -s /tmp/uptime.txt ]
then
  uptime_num=`expr $(cat /tmp/uptime.txt) \> 60`
  #if [ X$uptime_result == X ] || [ $(cat /tmp/uptime.txt)-gt 24 ]
  if [ $uptime_num -eq 1 ]
  then
    echo  -e "\033[31m\tError... Current Load $(cat /tmp/uptime.txt) ...... \033[0m"
  else
    echo  -e "\033[32m\tOK...\033[0m"
  fi
else
  echo -e "\033[31m\tCommand Error...\033[0m"
fi


# svc_perf gcstall -sr vnest 
echo  -en "\n\033[47;30m$ltime###vnest check\033[0m\n"
sshpass -p ChangeMe ssh  admin@$expect_node   svc_perf gcstall -sr vnest 2>&1 | awk {'print $7'} | grep "%" | sort -u -r | head -1  > /tmp/vnest_result.txt
if [ $? -eq 0 -a -s /tmp/vnest_result.txt ];then
  sed -i 's/'%'//g' /tmp/vnest_result.txt
  #stopped_num=`cat /tmp/vnest_result.txt`
  stopped_num=`expr $(cat /tmp/vnest_result.txt) \> 10` 
  #if [ X$stopped_num == X ] || [ $stopped_num -gt 10 ]
  if [ $stopped_num -eq 1 ]
  then
    echo  -e "\033[31m\tError... Current Stopped time $(cat /tmp/vnest_result.txt) \033[0m"
  else
    echo  -e "\033[32m\tOK...\033[0m"
  fi
else
  echo -e "\n\033[31m\tError...No output\033[0m\n"
fi


# svc_perf gcstall -sr resourcesvc
echo  -en "\n\033[47;30m$ltime###resourcesvc check\033[0m\n"
sshpass -p ChangeMe ssh  admin@$expect_node svc_perf gcstall -sr resourcesvc 2>&1 |awk {'print $7'} | grep "%" | sort -u -r | head -1 > /tmp/resource_result.txt
if [ $? -eq 0 -a -s /tmp/resource_result.txt ];then
  sed -i 's/'%'//g' /tmp/resource_result.txt
  #resource_num=`cat /tmp/resource_result.txt`
  resource_num=`expr $(cat /tmp/resource_result.txt) \> 10`
  #if [ X$resource_num == X ] || [ $resource_num -gt 10 ]
  if [ $stopped_num -eq 1 ]
  then
    echo  -e "\033[31m\tError... Current Stopped time $resource_num \033[0m"
  else
    echo  -e "\033[32m\tOK...\033[0m"
  fi
else
  echo -e "\033[31m\tError...No output\033[0m"
fi

#cm check
echo  -en "\n\033[47;30m$ltime###cm check\033[0m\n"
sshpass -p ChangeMe ssh  admin@$expect_node svc_perf gcstall -sr cm 2>&1 |awk {'print $7'} | grep "%" | sort -u -r | head -1 > /tmp/cm_result.txt
if [ $? -eq 0 -a -s /tmp/cm_result.txt ];then
  sed -i 's/'%'//g' /tmp/cm_result.txt
  #cm_num=`cat /tmp/cm_result.txt`
  cm_num=`expr $(cat /tmp/cm_result.txt) \> 10`
  #if [ X$cm_num == X ] || [ $cm_num -gt 10 ]
  if [ $cm_num -eq 1 ]
  then
    echo  -e "\033[31m\tError... Current Stopped time $cm_num \033[0m"
  else
    echo  -e "\033[32m\tOK...\033[0m"
  fi
else
  echo -e "\n\033[31m\tError...No output\033[0m\n"
fi


#svc_perf gcstall -sr blobsvc
echo  -en "\n\033[47;30m$ltime###blobsvc check\033[0m\n"
sshpass -p ChangeMe ssh  admin@$expect_node svc_perf gcstall -sr  blobsvc 2>&1 | awk {'print $7'} | grep "%" | sort -u -r | head -1 > /tmp/blobsvc_result.txt
if [ $? -eq 0 -a -s /tmp/blobsvc_result.txt ];then
  sed -i 's/'%'//g' /tmp/blobsvc_result.txt
  #blobsvc_num=`cat /tmp/blobsvc_result.txt`
  blobsvc_num=`expr $(cat /tmp/blobsvc_result.txt) \> 10`
  #if [ X$blobsvc_num == X ] || [ $blobsvc_num -gt 10 ]
  if [ $blobsvc_num -eq 1 ]
  then
    echo  -e "\033[31m\tError... Current Stopped time $blobsvc_num \033[0m"
  else
    echo  -e "\033[32m\tOK...\033[0m"
  fi
else
  echo -e "\n\033[31m\tError...No output\033[0m\n"
fi

#sudo xdoctor 
#echo -e "\033[47;30m$ltime###xdoctor check\033[0m\n"
#xdoctor_source=`sshpass -p ChangeMe ssh  admin@$expect_node sudo xdoctor`
#xdoctor_null=`sshpass -p ChangeMe ssh  admin@$expect_node sudo xdoctor|head -1`
#echo -e "$xdoctor_source\n"
#xdoctor_result=`sshpass -p ChangeMe ssh  admin@$expect_node sudo xdoctor 2>&1|grep -i "error"|grep -vE "Remote Service|Number of ERROR"`
#if test  -n "$xdoctor_null"
#then
#  if test $xdoctor_result; then
#     echo -e "\n\033[31m Error... $xdoctor_result \033\n"
#  else
#     echo -e "\n\033[32m OK...\033[0m\n"
#  fi
#else

#DNS health check
echo -en "\n\033[47;30m$ltime###dns server check\033[0m\n"
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
echo -en "\n\033[47;30m$ltime###ntp server check\033[0m\n"
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
