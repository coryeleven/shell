#!/bin/bash

#variable
sftp_dir=`date -d "-2day" +%Y%m%d`
del_sftp_dir=`date -d "-10day" +%Y%m%d`

rm -rf /emphant/logs/gateway/gateway-*log-$del_sftp_dir
gunzip /emphant/logs/gateway/gateway-*log-"$sftp_dir".gz
#source_log_name=`ls -rtlh /emphant/logs/gateway |awk '{print $NF}'|grep $sftp_dir`

#mkdir gateway dir
lftp -u dxpalv02,Lv02@1234 sftp://55.14.15.52:22/home/ft/dxpalv02/nalv02/LV02/gateway-dev << EOF
mkdir $sftp_dir & cd $sftp_dir
mput /emphant/logs/gateway/gateway-*log-$sftp_dir
exit
EOF

#put log sftp
#for file_name in $source_log_name
# do
# lftp -u dxpalv02,Lv02@1234 sftp://55.14.15.52:22/home/ft/dxpalv02/nalv02/LV02/gateway-uat << EOF
# put /emphant/logs/gateway/$file_name 
# exit
#EOF
# done

#lftp -u dxpalv02,Lv02@1234 sftp://55.14.15.52:22/home/ft/dxpalv02/nalv02/LV02/gateway-$sftp_dir << EOF
#mput /emphant/logs/gateway/gateway-*log-$sftp_dir
#exit
#EOF
