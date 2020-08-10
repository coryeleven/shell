#!/bin/bash
echo -e "###############netstat -ntlp|grep 80############### \n"
netstat -ntlp|grep 80
echo ""
echo -e "###############docker ps############### \n"
docker ps 
echo ""
echo -e "###############netstat -n |grep -i establish |wc -l###############\n"
netstat -n |grep -i  establish |wc -l 
echo ""
echo -e "###############netstat -n |grep -i  time_wait |wc -l############### \n"
netstat -n |grep -i time_wait |wc -l 
