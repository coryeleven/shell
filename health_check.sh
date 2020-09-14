  #!/bin/bash
  #test str 测试字符串是否不为空，为空则真
  svc_log -f ERROR.*REQUEST_BUCKET_QUERY -sr resourcesvc -start 1h 2>/tmp/query_resoult.txt
  query_resoult=`cat  /tmp/query_resoult.txt |grep -i "error"|grep -v "Filter"`
  echo -e "------REQUEST_BUCKET_QUER Bucket Error Check------"
  if test $query_resoult;then 
     echo -e "\033[31m Error...\n $query_resoult \033[0m"
  else
     echo -e "\033[32m No Error...\033[0m"
  fi
  

  #svc_dt check
  dt_resoult=`svc_dt check -l 2>&1 |grep -v "Total"|grep "Unready"|awk {'print $NF'}`
  echo  -e "\n------svc_dt check------" 
  if [ $dt_resoult != 0 ];then
     echo -e "\033[31m Error... \n $dt_resoult \033[0m" 
  else
     echo -e "\033[32m No Error...\033[0m"
  fi
  
  #svc_dt  events -sr resourcesvc -start '1 day ago'
  echo -e "\n------svc_dt event------"
  event_resoult=`svc_dt  events -sr resourcesvc -start '1 day ago' 2>&1|grep -i "error"`
  if test $event_resoult;then
      echo -e "\033[31m Error...\n $event_resoult \033[0m" 
  else
      echo -e "\033[32m No Error...\033[0m"
  fi
  #viprexec  fcli maintenance list 
  echo -e "\n------maintenance_mode  check------"
  maintenance_resoult=`viprexec fcli maintenance list 2>&1 |awk {'print $NF'}|grep -vE "MODE|ACTIVE|169"`
  if test $maintenance_resoult;then
     echo -e "\033[31m Error...\n $maintenance_resoult \033[0m" 
  else
     echo -e "\033[32m No Error...\033[0m"
  fi

#  doit uptime
  echo  -e "\n------doit uptime check------"
  uptime_resoult=`doit uptime|awk {'print $NF'}|grep -vE "ssh|login"|sort -r |head -1` 
  uptime_num=`expr $uptime_resoult \> 60` 
  if [ $uptime_num -eq  1 ]
  then
     echo  -e "\033[31m Current Load $uptime_resoult...... \033[0m"
  else
     echo  -e "\033[32m No Error...\033[0m"
  fi
# svc_perf gcstall -sr vnest 
  echo  -e "\n------vnest check------"
  svc_perf gcstall -sr vnest 2>&1 |awk {'print $7'}|grep "%"|sort -u -r |head -1  > /tmp/vnest_resoult.txt
  sed -i 's/'%'//g' /tmp/vnest_resoult.txt
  stopped_num1=`cat /tmp/vnest_resoult.txt` 
  stopped_num2=`echo "$stopped_num1 > 10"|bc`
  if [ $stopped_num2 -eq 1 ]
  then
     echo  -e "\033[31m Error... \n Current Stopped time $stopped_num1 \033[0m"
  else
     echo  -e "\033[32m No Error...\033[0m"
  fi
 
#  svc_perf gcstall -sr resourcesvc
   echo  -e "\n------resourcesvc  check------"
   svc_perf gcstall -sr resourcesvc 2>&1 |awk {'print $7'}|grep "%"|sort -u -r |head -1 >  /tmp/resource_resoult.txt
   sed -i 's/'%'//g' /tmp/resource_resoult.txt
   resource_num1=`cat /tmp/resource_resoult.txt`
   resource_num2=`echo "$resource_num1 > 10"|bc`
   if [ $resource_num2 -eq 1 ]
   then
     echo  -e "\033[31m Error... \n Current Stopped time $resource_num1 \033[0m"
   else
     echo  -e "\033[32m No Error...\033[0m"
   fi

#  svc_perf gcstall -sr cm
   echo  -e "\n------cm  check------"
   svc_perf gcstall -sr cm 2>&1|awk {'print $7'}|grep "%"|sort -u -r |head -1 >  /tmp/cm_resoult.txt
   sed -i 's/'%'//g' /tmp/cm_resoult.txt
   cm_num1=`cat /tmp/cm_resoult.txt`
   cm_num2=`echo "$cm_num1 > 10"|bc`
   if [ $cm_num2 -eq 1 ]
   then
     echo  -e "\033[31m Error... \n Current Stopped time $cm_num1 \033[0m"
   else
     echo  -e "\033[32m No Error...\033[0m"
   fi
  
#  svc_perf gcstall -sr blobsvc
   echo  -e "\n------blobsvc  check------"
   svc_perf gcstall -sr  blobsvc 2>&1|awk {'print $7'}|grep "%"|sort -u -r |head -1 >  /tmp/blobsvc_resoult.txt
   sed -i 's/'%'//g' /tmp/blobsvc_resoult.txt
   blobsvc_num1=`cat /tmp/blobsvc_resoult.txt`
   blobsvc_num2=`echo "$blobsvc_num1 > 10"|bc`
   if [ $blobsvc_num2 -eq 1 ]
   then
     echo  -e "\033[31m Error... \n Current Stopped time $blobsvc_num1 \033[0m"
   else
     echo  -e "\033[32m No Error...\033[0m"
   fi

#  sudo xdoctor 
  echo -e "\n------xdoctor check------"
  xdoctor_resoult=`sudo xdoctor 2>&1|grep -i "error"|grep -vE "Remote Service|Number of ERROR"`
  if test $xdoctor_resoult;then
     echo -e "\033[31m Error...\n $xdoctor_resoult \033"
  else
     echo -e "\033[32m No Error...\033[0m"
  fi

