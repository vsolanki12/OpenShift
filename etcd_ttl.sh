#!/bin/bash

if [ $# == 1 ]
 then
  CASE_ID=$1
  echo -e "$YELLOW`ls -l $HOME/$CASE_ID/ |egrep 'xz|gz|zip|tar'|grep -v sos`$NONE"
  echo -e -n "\e[1;43mChoose the must-gather from the above output:\e[0m"
  read CHOOSED_MUST_GATHER
  MUST_GATHER_File=`ls $HOME/$CASE_ID/$CHOOSED_MUST_GATHER/ | grep -i must`
  etcd_directory=`find $HOME/$CASE_ID/$CHOOSED_MUST_GATHER/$MUST_GATHER_File/ -type d -name openshift-etcd`
  for i in `ls $etcd_directory/pods/ | egrep -v 'pruner|guard|debug'`
   do
    cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep -i "took too long"|awk -F'T' '{print $1}'|uniq|sort > $HOME/tmp_dt.txt
    for dt in `cat $HOME/tmp_dt.txt|tail -3`
     do 
      echo "took too long messages date & time wise count $i $dt"
      echo "***********************************************************************************************************"
      for milli_sec in `cat $HOME/time_took_too_long_millisec.txt`
       do
        echo "more than $milli_sec"ms":`cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log | grep -i $dt| grep -i "took too long"| awk -F',' '{print $5}'  | awk -F':' '{print $2}'| tr -d '"'| grep  ms|awk '$1>'$milli_sec''|wc -l`"
      done
      cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log | grep -i $dt| grep -i "took too long"| awk -F',' '{print $5}'  | awk -F':' '{print $2}'| tr -d '"'| grep -v ms|grep -v m| awk -F'.' '{print $1}'|sort|uniq > $HOME/time_took_too_long_sec.txt  
      sec_count=`cat $HOME/time_took_too_long_sec.txt|wc -l`
      if [ $sec_count -gt 15 ]
       then
        echo "1 2 3 4 5 6 7 8 9 10 15 20 30 40 50"|tr ' ' '\n' > $HOME/time_took_too_long_sec.txt
      else
       cat $HOME/time_took_too_long_sec.txt|wc -l >/dev/null
      fi
      for sec in `cat $HOME/time_took_too_long_sec.txt`
       do 
        echo "more than $sec"s":`cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log | grep -i $dt| grep -i "took too long"| awk -F',' '{print $5}'  | awk -F':' '{print $2}'| tr -d '"'| egrep -v 'ms|m'|awk '$1>'$sec''|wc -l`"
      done
      cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log | grep -i $dt| grep -i "took too long"| awk -F',' '{print $5}'  | awk -F':' '{print $2}'| tr -d '"'| grep -v ms|grep m | awk -F'm' '{print $1}' |sort|uniq > $HOME/time_took_too_long_min.txt
      for min in `cat $HOME/time_took_too_long_min.txt`
       do
        echo "more than $min"m":`cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log | grep -i $dt| grep -i "took too long"| awk -F',' '{print $5}'  | awk -F':' '{print $2}'| tr -d '"'| grep -v ms|grep m | awk '$1>'$min''|wc -l`"
      done
      echo "========================================================================="$'\n'
    done
  done 
else
 echo -e "\e[1;31mKindly provide the case along side with the script name. Example ./etcd_ttl.sh case_number\e[0m"
fi
