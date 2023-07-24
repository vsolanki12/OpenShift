#!/bin/bash
#!/bin/sh
if [ $# == 1 ]
 then
  CASE_DIR=$1
  cp /dev/null $HOME/$CASE_DIR/pod_utilization.txt
  echo -e "`ls -l $HOME/$CASE_DIR/ | grep sos|egrep 'gz|xz|zip'`"
  echo -e -n "\e[1;43mChoose the sos-report from the above output:\e[0m"
  read SOS_DIR
  SOS_Final=`ls $HOME/$CASE_DIR/$SOS_DIR/`
  for i in `cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/crio/crictl_ps| awk '{print $1}'|grep -v CONTAINER`
   do
    podvalue=`cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/crio/crictl_ps|grep $i| awk '{print $9}'`
    podname=`cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/crio/crictl_pods | grep $podvalue|awk -F' ' '{print $6}'`
    echo "$podname|`cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/crio/crictl_stats |grep $i|awk '{print $2,$3,$4}'|tr ' ' '|'`" >> $HOME/$CASE_DIR/pod_utilization.txt
  done
  echo "Pod Names those are using high CPU"
  echo "*******************************************************" 
  echo "POD_NAME|CPU%|Memory|Disk"
  cat $HOME/$CASE_DIR/pod_utilization.txt |sed 's/::/|/' | awk -F\| '{ if ( $2 >= 30 ) print $0 }'
  echo "------------------------------------------------------------------------------------"
  echo ""
  echo "Pod Names those are using high Memory"
  echo "*******************************************************"
  echo "POD_NAME|CPU%|Memory|Disk"
  cat $HOME/$CASE_DIR/pod_utilization.txt |sed 's/::/|/' | awk -F\| '{ if ( $3 >= 1 ) print $0 }' | grep -i GB
  echo "------------------------------------------------------------------------------------"
else
  echo -e "\e[1;31mKindly provide the case along side with the script name. Example ./sos-report-check.sh case_number\e[0m"
fi
