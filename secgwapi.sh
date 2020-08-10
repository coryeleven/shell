#!/bin/bash
cat << EOF
**********please enter your choise:(1-6)******
(1) List Apps
(2) List Stors
(3) Create a App
(4) Create a Bucket
(5) Update Bucket
(6) Exit Menu.
EOF

username=k
password=123456
endpoint='http://55.13.33.40:8099'
secret=`echo -n $password | sha256sum | awk '{print $1}'`
read -p "Now select the top option to :" input 
case $input in 
1)
  curl -H "gw_secret:${username},${secret}" "$endpoint/api/v1/app";;

2)
  curl -H "gw_secret:${username},${secret}" "$endpoint/api/v1/stor";;

3)
  read -p "please input appid :"  appid
  read -p "please input appid's desc :" desc
  read -p "please app status(0:enable, 1:disable):" astatusid 
  curl  -X PUT -H "gw_secret:${username},${secret}" -d '{"id":"'$appid'","desc":"'{$desc}'","status":'$astatusid'}' "$endpoint/api/v1/app";;

4)
  read -p "please input bucket :" bucket
  read -p "please input bucket's desc :" bkdesc
  read -p "please input status (1开启防盗链,2关闭防盗链,3静态防盗链,4安全码检验) :" bkstatus
  read -p "please input storid:" storid 
  curl -X PUT -H "gw_secret:${username},${secret}" -d '{"id":"'$bucket'","desc":"'$bkdesc'","status":'$bkstatus',"stor":'$storid'}'  "$endpoint/api/v1/bucket";;

5)
  read -p "please input modify bucket :" update_bucket
  read -p "please input modify bucket's desc(bucket description(最大长度1024字节)) :" update_bkdesc
  read -p "please input modify status (1开启防盗链,2关闭防盗链,3静态防盗链,4安全码检验) :" update_bkstatus
  read -p "please input modify storid (后端S3(ECS)ID,默认值0):" update_storid
  curl  -X POST -H "gw_secret:${username},${secret}" -d '{"id":"'$update_bucket'","desc":"'$update_bkdesc'","status":'$update_bkstatus',"stor":'$update_storid'}' "$endpoint/api/v1/bucket";;
esac

