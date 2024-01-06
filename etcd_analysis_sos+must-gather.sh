#!/bin/bash
# TERMINAL COLORS -----------------------------------------------------------------
NONE='\033[00m'
RED='\033[01;31m'
GREEN='\033[01;32m'
YELLOW='\033[01;33m'
BLACK='\033[30m'
BLUE='\033[34m'
VIOLET='\033[35m'
CYAN='\033[36m'
GREY='\033[37m'

# For a colored background --------------------------------------------------------------------
B_RED='\033[01;41m'
B_GREEN='\033[01;42m'
B_YELLOW='\033[01;43m'
B_BLUE='\033[01;44m'
B_MAGENTA='\033[01;45m'
B_CYAN='\033[01;46m'
B_WHITE='\033[01;47m'


if [ $# == 1 ]
 then
   CASE_ID=$1
   cp /dev/null $HOME/$CASE_ID/pod_utilization.txt
   echo -e "`ls -l $HOME/$CASE_ID/ | grep sos|egrep 'gz|xz|zip'`"
   echo -e -n "\e[1;43mChoose the sos-report from the above output:\e[0m"
   read SOS_DIR
   SOS_Final=`ls $HOME/$CASE_ID/$SOS_DIR/`
   Confirm_MasterSOS=`ls $HOME/$CASE_ID/$SOS_DIR/$SOS_Final/etc/kubernetes/manifests | grep -i etcd-pod.yaml`
   if [ $Confirm_MasterSOS == "etcd-pod.yaml" ]
    then
     echo "======================================================================================================================================================"$'\n'
     echo -e "\e[1;43mChecking SOS Report System Level and Resource Utilization \e[0m"
     echo "===================================================================================="$'\n'
     echo -e "\e[1;31mHostname\e[0m"
     echo "----------------------------"
     cat $HOME/$CASE_ID/$SOS_DIR/$SOS_Final/hostname
     echo ""
     echo -e "\e[1;31mUptime\e[0m"
     echo "----------------------------"
     cat $HOME/$CASE_ID/$SOS_DIR/$SOS_Final/uptime
     echo ""
     echo -e "\e[1;31mKernel Version\e[0m"
     echo "----------------------------"
     cat $HOME/$CASE_ID/$SOS_DIR/$SOS_Final/uname
     echo ""
     echo -e "\e[1;31mSystem Information\e[0m"
     echo "------------------------------"
     cat $HOME/$CASE_ID/$SOS_DIR/$SOS_Final/dmidecode | grep -A2 "System Information"
     echo ""
     echo -e "\e[1;31mKdump(Kernel) Information about enabled or disabled\e[0m"
     echo "--------------------------------------------------------------------------"$'\n'
     cat $HOME/$CASE_ID/$SOS_DIR/$SOS_Final/sos_commands/systemd/systemctl_list-unit-files | grep kdump
     echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"$'\n'     
     echo -e "$RED""Load Avg on Node""$NONE"
     echo "******************************************"
     xsos -com $HOME/$CASE_ID/$SOS_DIR/$SOS_Final | grep -i LoadAvg
     echo "======================================================================================================================================================"$'\n'
     echo -e "$RED""Memory Utilization on Node""$NONE"
     echo "******************************************"
     xsos -com $HOME/$CASE_ID/$SOS_DIR/$SOS_Final | grep -A11 MEMORY 
     echo "======================================================================================================================================================"$'\n'
     echo -e "$RED""POD Utilization Check""$NONE"
     echo "******************************************"
     for i in `cat $HOME/$CASE_ID/$SOS_DIR/$SOS_Final/sos_commands/crio/crictl_ps| awk '{print $1}'|grep -v CONTAINER`
      do
       podvalue=`cat $HOME/$CASE_ID/$SOS_DIR/$SOS_Final/sos_commands/crio/crictl_ps|grep $i| awk '{print $9}'`
       podname=`cat $HOME/$CASE_ID/$SOS_DIR/$SOS_Final/sos_commands/crio/crictl_pods | grep $podvalue|awk -F' ' '{print $6}'`
       echo "$podname|`cat $HOME/$CASE_ID/$SOS_DIR/$SOS_Final/sos_commands/crio/crictl_stats |grep $i|awk '{print $2,$3,$4}'|tr ' ' '|'`" >> $HOME/$CASE_ID/pod_utilization.txt
     done
     echo -e "$RED""Pod Names those are using high CPU""$NONE"
     echo "*******************************************************"
     echo -e "$YELLOW""POD_NAME|CPU%|Memory|Disk""$NONE"
     cat $HOME/$CASE_ID/pod_utilization.txt |sed 's/::/|/' | awk -F\| '{ if ( $2 >= 30 ) print $0 }'
     echo "------------------------------------------------------------------------------------"
     echo ""
     echo -e "$YELLOW""Pod Names those are using high Memory""$NONE"
     echo "*******************************************************"
     echo "POD_NAME|CPU%|Memory|Disk"
     cat $HOME/$CASE_DIR/pod_utilization.txt |sed 's/::/|/' | awk -F\| '{ if ( $3 >= 1 ) print $0 }' | grep -i GB
     echo "------------------------------------------------------------------------------------"
     echo "======================================================================================================================================================"$'\n'
     echo -e "$B_RED"'Checking Journal Logs for "task etcd blocked for more than 120 seconds" error as per KCS:https://access.redhat.com/solutions/1185723'"$NONE"
     echo "***************************************************************************************************************************************************"
     Error_Count=`cat $HOME/$CASE_ID/$SOS_DIR/$SOS_Final/sos_commands/logs/journalctl_--no-pager_--boot | grep -A20 "kernel: INFO: task etcd"|wc -l`
     if [ $Error_Count -gt 0 ]
      then
       echo -e "$RED""The Backend disk is having issue Customer needs to check at their end""$NONE"
       echo -e "$RED""Total Error:""$NONE"`cat $HOME/$CASE_ID/$SOS_DIR/$SOS_Final/sos_commands/logs/journalctl_--no-pager_--boot | grep -A20 "kernel: INFO: task etcd"|wc -l`
       cat $HOME/$CASE_ID/$SOS_DIR/$SOS_Final/sos_commands/logs/journalctl_--no-pager_--boot | grep -A20 "kernel: INFO: task etcd"|tail -22
     else
       echo -e "$GREEN""No such error found in Logs""$NONE"
     fi
     echo "======================================================================================================================================================"$'\n'
     echo -e "$RED""Checking some error for etcd in Journalctl logs: sos_commands/logs/journalctl_--no-pager_--boot""$NONE"
     echo "*******************************************************************************************************"
     echo -e "$YELLOW""etcdserver: request timed out:""$NONE"`cat $HOME/$CASE_ID/$SOS_DIR/$SOS_Final/sos_commands/logs/journalctl_--no-pager_--boot | grep 'etcdserver: request timed out'|wc -l`
     echo -e "$YELLOW""etcd failed: reason withheld:""$NONE"`cat $HOME/$CASE_ID/$SOS_DIR/$SOS_Final/sos_commands/logs/journalctl_--no-pager_--boot | grep 'etcd failed: reason withheld'|wc -l`
     echo -e "$YELLOW""etcd-readiness failed: reason withheld:""$NONE"`cat $HOME/$CASE_ID/$SOS_DIR/$SOS_Final/sos_commands/logs/journalctl_--no-pager_--boot | grep 'etcd-readiness failed: reason withheld'|wc -l`
     echo "======================================================================================================================================================"$'\n'
     echo -e -n "$RED""Do You want to proceed to check the packet drops[YES/NO]:""$NONE"
     read input
     if [ $input == "YES" ] || [ $input == "Yes" ] || [ $input == "yes" ]
      then
       echo -e "$RED""Packet Drop Checking""$NONE"
       echo "***********************************************"
       cat $HOME/$CASE_ID/$SOS_DIR/$SOS_Final/sos_commands/networking/ip_-s_-d_link
     else
      break
     fi
     echo "======================================================================================================================================================"$'\n'
   else
       echo "Not a master sos-report"
   fi
   echo "======================================================================================================================================================"$'\n'
   echo -e -n "$RED""Do You want to proceed for Must-Gather Analysis for ETCD logs[YES/NO]:""$NONE"
   read input
   if [ $input == "YES" ] || [ $input == "Yes" ] || [ $input == "yes" ]
    then
     echo -e "$B_CYAN""Checking Must-gather for etcd Data""$NONE"
     echo "*****************************************************************************************************************************************"$'\n'
     echo -e "$YELLOW`ls -l $HOME/$CASE_ID/ |egrep 'xz|gz|zip|tar'|grep -v sos`$NONE"
     echo -e -n "\e[1;43mChoose the must-gather from the above output:\e[0m"
     read CHOOSED_MUST_GATHER
     CL_SCOPE_CHECK_DIR=`find $HOME/$CASE_ID/$CHOOSED_MUST_GATHER/$MUST_GATHER_File/ -type d -name cluster-scoped-resources`
     MUST_GATHER_File=`ls $HOME/$CASE_ID/$CHOOSED_MUST_GATHER/ | grep -i must`
     etcd_directory=`find $HOME/$CASE_ID/$CHOOSED_MUST_GATHER/$MUST_GATHER_File/ -type d -name openshift-etcd`
     #PV_CHECK_DIR=`find $HOME/$CASE_ID/$CHOOSED_MUST_GATHER/$MUST_GATHER_File/ -type d -name cluster-scoped-resources`
     ETCD_INFO_DIR=`find $HOME/$CASE_ID/$CHOOSED_MUST_GATHER/$MUST_GATHER_File/ -type d -name etcd_info`
     ETCD_OPERATOR_DIR=`find $HOME/$CASE_ID/$CHOOSED_MUST_GATHER/$MUST_GATHER_File/ -type d -name openshift-etcd-operator`
     omc use $HOME/$CASE_ID/$CHOOSED_MUST_GATHER/$MUST_GATHER_File
     CL_VERSION=`omc get clusterversion|awk '{print $2}' | grep -v VERSION|awk -F'.' '{print $1"."$2}'`
     echo -e "$B_CYAN""etcd pod restart count check""$NONE"
     echo "*****************************************************************************************************************************************"$'\n'
     omc -n openshift-etcd get pods -l k8s-app=etcd
     echo "======================================================================================================================================================"$'\n'
     echo -e "$B_CYAN""Checking etcd encryption enabled""$NONE"
     echo "*****************************************************************************************************************************************"$'\n'
     ENCRYPTION=`omc get apiserver cluster -ojson | jq '.spec.encryption.type' | tr -d '"'`
     if [ $ENCRYPTION == "aescbc" ] || [ $ENCRYPTION == "aesgcm" ]
      then
       echo -e "$VIOLET""ETCD encryption is enabled""$NONE"
       omc get apiserver cluster -ojson | jq '.spec.encryption'
     else
       echo -e "$YELLOW""ETCD encryption is not enabled""$NONE"
     fi
     echo "======================================================================================================================================================"$'\n'
     echo -e "\n\e[1;42mSecret details from NameSpace openshift-kube-apiserver\e[0m\n************************************************************************"
     echo -e "$BLUE""Total Number of Secrets:"`omc get secrets -n openshift-kube-apiserver|grep -v NAME |awk '{print $1}' |wc -l`"$NONE"
     echo -e "$BLUE""No. of Encryption-config Secrets:"`omc get secrets -n openshift-kube-apiserver|grep -v NAME |awk '{print $1}' | awk '{print $0}' |  awk -F'-' 'BEGIN {OFS="-"} {$NF=""} 1' | sort | uniq -c | sort -rn|sed 's/-$//' |grep "encryption-config"`"$NONE"
     echo "========================================================================================================================================================="$'\n\n'
     echo -e "$RED""etcd Members details""$NONE"
     echo "*************************************"
     echo "|NAME|ID|ClientURL|peerURL" > $HOME/etcd_member_list.txt
     echo "|++++++++++|+++++++++|+++++++++|+++++++++" >>$HOME/etcd_member_list.txt
     cat $ETCD_INFO_DIR/member_list.json | jq '.members[]|"|" + (.name|tostring) + " |" + (.ID|tostring) + " |" + (.clientURLs[]|tostring) + " |" + (.peerURLs[]|tostring)'| tr -d '"' >> $HOME/etcd_member_list.txt
     echo -e "$YELLOW""`cat  $HOME/etcd_member_list.txt|column -t -s "|"`""$NONE"
     echo "======================================================================================================================================================"$'\n'
     echo -e "$RED""etcd Health Status""$NONE"
     echo "***********************************"
     echo -e "$YELLOW""`cat $ETCD_INFO_DIR/endpoint_health.json| jq '.[]|"" + (.endpoint|tostring) + " | is healthy: " + (.health|tostring) + " |successfully committed proposal: took =" + (.took|tostring)'|tr -d '"'`""$NONE"
     echo "======================================================================================================================================================"$'\n'
     echo -e "$RED""etcd endpoint status -w table""$NONE"
     echo "***************************************"
     echo "|Leader ID|Member_ID|Revision|Version|RaFT_INDEX|RaftTerm|DBSize|DBUsed|Difference" > $HOME/etcd_enpoint.txt
     echo "|++++++++++|+++++++++|+++++++++|+++++++++|+++++++++|+++++++++|+++++++++|+++++++++|+++++++++">> $HOME/etcd_enpoint.txt
     cat $ETCD_INFO_DIR/endpoint_status.json | jq '.[].Status|"|" + (.leader|tostring) + " |" + (.header.member_id|tostring) + " |" + (.header.revision|tostring) + " |" + (.version|tostring) + " |" + (.raftIndex|tostring) + " |" + (.raftTerm|tostring) + " |" + ((.dbSize)/1024/1024|tostring)+ "MB" + " |" + ((.dbSizeInUse)/1024/1024|tostring)+ "MB" + " |" + ((.dbSize - .dbSizeInUse)/.dbSizeInUse*100|tostring)+"%"'|tr -d '"' >> $HOME/etcd_enpoint.txt
     echo -e "$YELLOW""`cat $HOME/etcd_enpoint.txt|column -t -s "|"`""$NONE"
     echo "======================================================================================================================================================"$'\n'
     echo -e "$RED""etcd endpoint auto defragmentation status""$NONE"
     echo "****************************************************"
     ETCD_ADEFRAG_LOG=`cat $ETCD_OPERATOR_DIR/pods/etcd-operator*/etcd-operator/etcd-operator/logs/current.log|grep "backend store fragmented"|wc -l`
     if [ $ETCD_ADEFRAG_LOG -eq 0 ]
      then
       echo -e "$GREEN""No Auto-Defragmentation logs present""$NONE"
     else
      cat $ETCD_OPERATOR_DIR/pods/etcd-operator*/etcd-operator/etcd-operator/logs/current.log|grep "backend store fragmented" > $HOME/$CASE_ID/etcd_fragmentation.log
      echo  -e "$RED"`cat $ETCD_OPERATOR_DIR/pods/etcd-operator*/etcd-operator/etcd-operator/logs/current.log|grep "backend store fragmented"|tail -3`"$NONE"$'\n'
     fi
     echo "======================================================================================================================================================"$'\n'
     for i in `ls $etcd_directory/pods/ | egrep -v 'pruner|guard|debug'|grep -i etcd`
      do
       echo $i
       echo "++++++++++++++++++++++++++++++++++++++++++++"
       echo -e "\e[1;33metcd last defragmentation status:\e[0m`cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep 'finished defragment'|tail -1`"
       echo -e "\e[1;33metcd server is likely overloaded messages:\e[0m`cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep 'leader is overloaded likely'|wc -l`"
       echo -e "\e[1;33metcd server overloaded network messages:\e[0m`cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep 'overloaded network'|wc -l`"
       echo -e "\e[1;33mtook too long messages count:\e[0m `cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep 'took too long'|wc -l`"
       echo -e "\e[1;33mfailed to reach the peer URL:\e[0m `cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep 'failed to reach the peer URL'|wc -l`"
       echo -e "\e[1;33mntp clock difference messages count:\e[0m `cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep 'clock difference'|wc -l`"
       echo -e "\e[1;33mfailed to send out heartbeat on time messages count:\e[0m `cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep 'failed to send out heartbeat on time'|wc -l`"
       echo -e "\e[1;33mdatabase space exceeded messages count:\e[0m `cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep 'database space exceeded'|wc -l`"
       echo -e "\e[1;33mleader changed messages count:\e[0m `cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep 'leader changed'|wc -l`"
       echo -e "\e[1;33metcdserver request timed out messages count:\e[0m `cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep 'etcdserver: request timed out'|wc -l`"
       echo -e "\e[1;33mtransport is closing messages count:\e[0m `cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep 'transport is closing'|wc -l`"
       echo -e "\e[1;33mcontext deadline exceeded messages count:\e[0m `cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep 'context deadline exceeded'|wc -l`"
       echo -e "\e[1;33mtimed out waiting for read index response messages count:\e[0m `cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep 'timed out waiting for read index response'|wc -l`"
       echo -e "\e[1;33mcontext canceled messages count:\e[0m `cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep 'context canceled'|wc -l`"
       echo -e "\e[1;33mwaiting for ReadIndex response took too long messages count:\e[0m `cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep 'waiting for ReadIndex response took too long'|wc -l`"
       echo -e "\e[1;33metcd High Fsync Durations error messages count:\e[0m `cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep 'slow fdatasync'|wc -l`"
       echo -e "\e[1;33metcd Highest Fsync Durations:\e[0m `cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep 'slow fdatasync'|awk -F',' '{print $5}' | awk -F':' '{print $2}'| sort| tail -1`"
       if [[ $CL_VERSION = 4.10 ]] || [[ $CL_VERSION > 4.10 ]]
        then
         echo -e "\e[1;33mCompaction highest seconds:\e[0m\n`cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep "compaction"| grep -v downgrade| grep -E "[0-9]+(.[0-9]+)s"|cut -d " " -f4 |  cut -d "," -f3 | cut -d ":" -f2| grep -v took  |sort| tail -6`"
         echo -e "\e[1;33mCompaction highest ms:\e[0m\n`cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep "compaction"| grep -v downgrade| grep -E "[0-9]+(.[0-9]+)ms"|cut -d " " -f4 |  cut -d "," -f3 | cut -d ":" -f2| grep -v took  |sort| tail -6`"
       elif [[ $CL_VERSION = 4.8 ]] || [[ $CL_VERSION > 4.8 ]]
        then
         echo -e "\e[1;33mCompaction highest seconds:\e[0m\n`cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep "compaction"| grep -v downgrade| grep -E "[0-9]+(.[0-9]+)s"|grep -o '[^,]*$'| cut -d":" -f2|grep -oP '"\K[^"]+'|sort|grep -v size  |tail -6`"
         echo -e "\e[1;33mCompaction highest ms:\e[0m\n`cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep "compaction"| grep -v downgrade| grep -E "[0-9]+(.[0-9]+)ms"|grep -o '[^,]*$'| cut -d":" -f2|grep -oP '"\K[^"]+'|sort|grep -v size |tail -6`"
       elif [[ $CL_VERSION = 4.7 ]]
        then
         echo -e "\e[1;33mCompaction highest seconds:\e[0m\n`cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep "compaction"| grep -E "[0-9]+(.[0-9]+)s"|cut -d " " -f13| cut -d ')' -f 1 |sort|grep -v size |tail -6`"
         echo -e "\e[1;33mCompaction highest ms:\e[0m\n`cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep "compaction"|grep "compaction"| grep -E "[0-9]+(.[0-9]+)ms"|cut -d " " -f13| cut -d ')' -f 1 |sort|grep -v size |tail -6`"
       else
         echo -e "\e[1;33mCompaction highest seconds:\e[0m\n`cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep "compaction"| grep -E "[0-9]+(.[0-9]+)s"|cut -d " " -f13| cut -d ')' -f 1 |sort|tail -6`"
         echo -e "\e[1;33mCompaction highest ms:\e[0m\n`cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep "compaction"| grep -E "[0-9]+(.[0-9]+)ms"|cut -d " " -f13| cut -d ')' -f 1 |sort|tail -6`"
       fi
       echo "------------------------------------------------------------------------------------------------------------------------------------------------------"
     done
     echo "========================================================================================================================================================="$'\n\n'
   else
    break
   fi
else
 echo -e "$RED Kindly provide the case along side with the script name. Example: ./must_gather_check.sh <case_number> $NONE"
fi
