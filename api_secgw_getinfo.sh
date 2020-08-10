#!/bin/bash
#backup bucket Info
appid_date_txt=`date +%Y%m%d`appid
appid_backup_txt=`date +%Y%m%d`appid_backup.txt
bucket_date_txt="`date +%Y%m%d`"bucket
bucket_backup_txt="`date +%Y%m%d`"bucket_backup.txt
if [ -f $bucket_date_txt ];then
    echo "$bucket_date_txt exist,Please delete it"
    rm -rvf $bucket_date_txt
fi
curl -H'gw_secret:k,8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92' 'http://55.13.33.39:8099/api/v1/bucket' > $bucket_date_txt
cat  $bucket_date_txt |sed 's/},/\n/g'|sed 's/{//g'|sed 's/}//g'|sed 's/"//g'|sed 's#\\##g'|sed 's/,/ /g'|sed  '$d'|sed 's/data://g'  >$bucket_backup_txt
if [ -f $bucket_backup_txt ];then
    echo "backup successful,$bucket_backup_txt"
  else
    echo "backup failed,Please try again"
fi


#backup appid
if [ -f $appid_date_txt ];then
    echo "$appid_date_txt exist,Please delete it"
    rm -rvf $appid_date_txt
fi
curl -H'gw_secret:k,8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92' 'http://55.13.33.39:8099/api/v1/app' > $appid_date_txt
cat $appid_date_txt |sed 's/},/\n/g'|sed 's/{//g'|sed 's/}//g'|sed 's/"//g'|sed 's#\\##g'|sed 's/,/ /g'|sed  '$d'|sed 's/data://g' > $appid_backup_txt
if [ -f $appid_backup_txt ];then
    echo "backup successful,$appid_backup_txt"
  else
    echo "backup failed,Please try again"
fi

rm -rf $bucket_date_txt
rm -rf $appid_date_txt
