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
   echo -e "$YELLOW`ls -l $HOME/$CASE_ID/ |egrep 'xz|gz|zip|tar'|grep -v sos`$NONE"
   echo -e -n "\e[1;43mChoose the must-gather from the above output:\e[0m"
   read CHOOSED_MUST_GATHER
   omg use $HOME/$CASE_ID/$CHOOSED_MUST_GATHER > /tmp/must-gather-used.txt
   echo -e "\n\e[1;44m $CHOOSED_MUST_GATHER File used for this output \e[0m"
   echo "*************************************************************************"
   omg use $HOME/$CASE_ID/$MUST_GATHER >/tmp/must-gather-used.txt
   echo -e "\n\e[1;42mCluster Infrastructure Check\e[0m\n*********************************************"
   echo -e "$YELLOW""Platform Type:`omg get infrastructure/cluster -o json | jq '.spec.platformSpec.type'`""$NONE"
   echo "==========================================================================================================================================================="$'\n\n'
   echo -e "\n\e[1;42mCluster Network Check\e[0m\n*********************************************"
   omg get network/cluster -oyaml| grep -v "f:status:" |grep "status:" -A7|grep -v status
   echo "==========================================================================================================================================================="$'\n\n'
   echo -e "\n\e[1;46mCluster version\e[0m:\n `omg get clusterversion`" 
   CL_VERSION=`omg get clusterversion|awk '{print $2}' | grep -v VERSION|awk -F'.' '{print $1"."$2}'`
   echo "==========================================================================================================================================================="$'\n\n'
   echo -e "\n\e[1;46mCluster version History [Completion_Date Version]\e[0m"
   echo "*********************************************************************************"
   omg get clusterversion -ojson | jq -r '.status.history[]| "\(.completionTime) \(.version)"' 
   echo "==========================================================================================================================================================="$'\n\n'
   omg get nodes > $HOME/CHECK_LOGS/node_details.txt
   echo -e "\n\e[1;44mNode Count\e[0m"
   echo "*************************************************************************"
   echo -e "$CYAN`cat $HOME/CHECK_LOGS/node_details.txt |awk '{print $3}'| grep -v ROLES |uniq -c|sort`$NONE"
   echo -e "$YELLOW""TOTAL NODE COUNT=`cat $HOME/CHECK_LOGS/node_details.txt |awk '{print $3}'| grep -v ROLES | wc -l`""$NONE"
   echo -e "\n\e[1;44mNode Status Check Options\e[0m"
   echo "*************************************************************************"
   echo -n -e "$BLUE""Do you want to list all the nodes[Yes/NO]:""$NONE"
   read NODE_INPUT
   if [ $NODE_INPUT == "Yes" ] || [ $NODE_INPUT == "YES" ] || [ $NODE_INPUT == "yes" ]
    then
     omg get nodes
   else
    break
   fi
   echo "==========================================================================================================================================================="$'\n\n'
   echo -e "\n\e[1;44mNode Annotations Check Options\e[0m"
   echo "*************************************************************************"
   echo -n -e "$BLUE""Do you want to list all the nodes[Yes/NO]:""$NONE"
   read ANNOT_INPUT
   if [ $ANNOT_INPUT == "Yes" ] || [ ANNOT_INPUT == "YES" ] || [ $ANNOT_INPUT == "yes" ]
    then
     echo -e "\nAnnotations output file\n*******************************************************************************" > $HOME/$CASE_ID/Annotations_file.txt
     for i in `omg get nodes|grep -v NAME|awk '{print $1}'`
      do
       echo -e "\n\e[1;42m$i\e[0m\n*******************************************************************************" >> $HOME/$CASE_ID/Annotations_file.txt
       omg get node $i -ojson | jq -r '.metadata.annotations' >> $HOME/$CASE_ID/Annotations_file.txt
     done
     echo -e "\e[1:31mAnnotation File Created $HOME/$CASE_ID/Annotations_file.txt\e[0m"
   else
    break
   fi
   echo "==========================================================================================================================================================="$'\n\n'
   echo -e "\n\e[1;44mControl plane pod revisions\e[0m"
   echo "************************************************************************"
   for static in etcd kubeapiserver kubecontrollermanager kubescheduler
    do
     echo -e "====== ${static} ======"
     omg get ${static} cluster -o json | jq -r '.status.conditions[] | select(.type == "NodeInstallerProgressing") | .message'
    done
   echo "==========================================================================================================================================================="$'\n\n'
   echo "*************************************************************************"
   echo -e "\n\e[1;42mNode NotReady state details\e[0m\n************************************************************************"
   NOT_READY=`omg get nodes | egrep -v 'ROLES'|egrep -i 'NotReady|unknown' | wc -l`
     if [ $NOT_READY -eq 0 ]
      then
       echo -e "$GREEN""No Node is in NotReady state""$NONE"
     else
       echo -e "$RED""`omg get nodes | egrep -v 'ROLES'|egrep -i 'NotReady|unknown'`""$NONE"
     fi
   echo "==========================================================================================================================================================="$'\n\n'
   #echo -e "\n\e[1;42mCluster Operator details\e[0m\n************************************************************************"
   #omg get nodes
   #echo "==========================================================================================================================================================="$'\n\n'
   echo -e "\n\e[1;41mCluster Operator which are in PROGRESSING/DEGRADED state\e[0m\n************************************************************************"
   omg get co | awk '$4=="True"||$5=="True"'
   omg get co | awk '$4=="True"||$5=="True"' | awk '{print $1}' > /tmp/Failed_ClusterOperator_NAME.txt
   echo "==========================================================================================================================================================="$'\n\n'
   Degraded_CO=`cat /tmp/Failed_ClusterOperator_NAME.txt|wc -l`
   if [ $Degraded_CO -gt 0 ]
    then
     echo -e "\n\e[1;41mLogs file of Cluster Operator which are in PROGRESSING/DEGRADED state\e[0m\n************************************************************************"
     for i in `cat /tmp/Failed_ClusterOperator_NAME.txt`
      do
       if [ $i == "storage" ]
        then
         Name_Space_name=openshift-cluster-storage-operator
         Operator_pod=`omg get pods -n $Name_Space_name | grep -i $i|grep -i operator|awk '{print $1}'`
         omg logs $Operator_pod -n $Name_Space_name > $HOME/$CASE_ID/Operator_"$i"_"$Name_Space_name"_"$Operator_pod".log
         echo -e "\e[1:34mLog File Created $HOME/$CASE_ID/Operator_"$i"_"$Name_Space_name"_"$Operator_pod".log\e[0m"
       elif [ $i == "baremetal" ]
        then
         Name_Space_name=`cat $HOME/OpenShift/CO_NS.txt|grep $i|awk '{print $2}'|uniq`
         Operator_pod=`omg get pods -n $Name_Space_name | grep -i $i|grep -i operator|awk '{print $1}'`
         omg logs $Operator_pod -c cluster-baremetal-operator -n $Name_Space_name > $HOME/$CASE_ID/Operator_"$i"_"$Name_Space_name"_"$Operator_pod".log
         echo -e "\e[1:34mLog File Created $HOME/$CASE_ID/Operator_"$i"_"$Name_Space_name"_"$Operator_pod".log\e[0m"
       elif [ $i == "cloud-credential" ]
        then
         Name_Space_name=openshift-cluster-storage-operator
         Operator_pod=`omg get pods -n $Name_Space_name | grep -i $i|grep -i operator|awk '{print $1}'`
         omg logs $Operator_pod -c cloud-credential-operator -n $Name_Space_name > $HOME/$CASE_ID/Operator_"$i"_"$Name_Space_name"_"$Operator_pod".log
         echo -e "\e[1:34mLog File Created $HOME/$CASE_ID/Operator_"$i"_"$Name_Space_name"_"$Operator_pod".log\e[0m"
       elif [ $i == "operator-lifecycle-manager-catalog" ]
        then
         Name_Space_name=`cat $HOME/OpenShift/CO_NS.txt|grep $i|awk '{print $2}'|uniq`
         Operator_pod=`omg get pods -n $Name_Space_name | grep -i catalog |grep -i operator|awk '{print $1}'`
         omg logs $Operator_pod -n $Name_Space_name > $HOME/$CASE_ID/Operator_"$i"_"$Name_Space_name"_"$Operator_pod".log
         echo -e "\e[1:34mLog File Created $HOME/$CASE_ID/Operator_"$i"_"$Name_Space_name"_"$Operator_pod".log\e[0m"
       elif [ $i == "operator-lifecycle-manager-packageserver" ]
        then
         Name_Space_name=`cat $HOME/OpenShift/CO_NS.txt|grep $i|awk '{print $2}'|uniq`
         Operator_pod=`omg get pods -n $Name_Space_name | grep -i packageserver|awk '{print $1}'`
         for j in $Operator_pod
          do 
           omg logs $j -n $Name_Space_name > $HOME/$CASE_ID/Operator_$i_$Name_Space_name_"$j".log
           echo -e "\e[1:34mLog File Created $HOME/$CASE_ID/Operator_"$i"_"$Name_Space_name"_"$j".log\e[0m"
         done 
       elif [ $i == "machine-api" ]
        then
         Name_Space_name=`cat $HOME/OpenShift/CO_NS.txt|grep $i|awk '{print $2}'|uniq`
         Operator_pod=`omg get pods -n $Name_Space_name | grep -i $i|grep -i operator|awk '{print $1}'`
         omg logs $Operator_pod -c cluster-baremetal-operator -c machine-api-operator -n $Name_Space_name > $HOME/$CASE_ID/Operator_"$i"_"$Name_Space_name"_"$Operator_pod".log
         echo -e "\e[1:34mLog File Created $HOME/$CASE_ID/Operator_"$i"_"$Name_Space_name"_"$Operator_pod".log\e[0m"
       elif [ $i == "config-operator" ]
        then
         Name_Space_name=openshift-config-operator
         Operator_pod=`omg get pods -n $Name_Space_name | grep -i $i|grep -i operator|awk '{print $1}'`
         omg logs $Operator_pod -c cluster-baremetal-operator -n $Name_Space_name > $HOME/$CASE_ID/Operator_"$i"_"$Name_Space_name"_"$Operator_pod".log
         echo -e "\e[1:34mLog File Created $HOME/$CASE_ID/Operator_"$i"_"$Name_Space_name"_"$Operator_pod".log\e[0m"
       elif [ $i == "cluster-autoscaler" ]
        then
         Name_Space_name=`cat $HOME/OpenShift/CO_NS.txt|grep $i|awk '{print $2}'|uniq`
         Operator_pod=`omg get pods -n $Name_Space_name | grep -i $i|grep -i operator|awk '{print $1}'` 
         omg logs $Operator_pod -c cluster-autoscaler-operator -n $Name_Space_name > $HOME/$CASE_ID/Operator_"$i"_"$Name_Space_name"_"$Operator_pod".log
         echo -e "\e[1:34mLog File Created $HOME/$CASE_ID/Operator_"$i"_"$Name_Space_name"_"$Operator_pod".log\e[0m"
       elif [ $i == "dns" ]
        then
         Name_Space_name=`cat $HOME/OpenShift/CO_NS.txt|grep $i|awk '{print $2}'|uniq`
         Operator_pod=`omg get pods -n $Name_Space_name | grep -i $i|grep -i operator|awk '{print $1}'`
         omg logs $Operator_pod -c dns-operator -n $Name_Space_name > $HOME/$CASE_ID/Operator_"$i"_"$Name_Space_name"_"$Operator_pod".log
         echo -e "\e[1:34mLog File Created $HOME/$CASE_ID/Operator_"$i"_"$Name_Space_name"_"$Operator_pod".log\e[0m"
       elif [ $i == "monitoring" ]
        then
         Name_Space_name=`cat $HOME/OpenShift/CO_NS.txt|grep $i|awk '{print $2}'|uniq`
         Operator_pod=`omg get pods -n $Name_Space_name | grep -i $i|grep -i operator|awk '{print $1}'`
         for j in $Operator_pod
          do
           omg logs $j -c cluster-monitoring-operator -n $Name_Space_name > $HOME/$CASE_ID/Operator_$i_$Name_Space_name_"$j".log
           echo -e "\e[1:34mLog File Created $HOME/$CASE_ID/Operator_$i_$Name_Space_name_"$j".log\e[0m"
         done
       elif [ $i == "operator-lifecycle-manager" ]
        then
         Name_Space_name=`cat $HOME/OpenShift/CO_NS.txt|grep $i|awk '{print $2}'|uniq`
         Operator_pod=`omg get pods -n $Name_Space_name | grep -i "olm-operator"|awk '{print $1}'`
         omg logs $Operator_pod -n $Name_Space_name > $HOME/$CASE_ID/Operator_"$i"_"$Name_Space_name"_"$Operator_pod".log 
         echo -e "\e[1:34mLog File Created $HOME/$CASE_ID/Operator_"$i"_"$Name_Space_name"_"$Operator_pod".log\e[0m"
       elif [ $i == "ingress" ]
        then
         Name_Space_name=`cat $HOME/OpenShift/CO_NS.txt|grep $i|awk '{print $2}'|uniq`
         Operator_pod=`omg get pods -n $Name_Space_name | grep -i $i|grep -i operator|awk '{print $1}'`
         omg logs $Operator_pod -c ingress-operator -n $Name_Space_name > $HOME/$CASE_ID/Operator_"$i"_"$Name_Space_name"_"$Operator_pod".log 
         echo -e "\e[1:34mLog File Created $HOME/$CASE_ID/Operator_"$i"_"$Name_Space_name"_"$Operator_pod".log\e[0m"
       elif [ $i == "machine-approver" ]
        then
         Name_Space_name=`cat $HOME/OpenShift/CO_NS.txt|grep $i|awk '{print $2}'|uniq`
         Operator_pod=`omg get pods -n $Name_Space_name | grep -i $i|awk '{print $1}'` 
         omg logs $Operator_pod -c ingress-operator -c machine-approver-controller -n $Name_Space_name > $HOME/$CASE_ID/Operator_"$i"_"$Name_Space_name"_"$Operator_pod".log
         echo -e "\e[1:34mLog File Created $HOME/$CASE_ID/Operator_"$i"_"$Name_Space_name"_"$Operator_pod".log\e[0m"
       else
        Name_Space_name=`cat $HOME/OpenShift/CO_NS.txt|grep $i|awk '{print $2}'|uniq`
        Operator_pod=`omg get pods -n $Name_Space_name | grep -i $i|grep -i operator|awk '{print $1}'`
        omg logs $Operator_pod -n $Name_Space_name > $HOME/$CASE_ID/Operator_"$i"_"$Name_Space_name"_"$Operator_pod".log 
        echo -e "\e[1:34mLog File Created $HOME/$CASE_ID/Operator_"$i"_"$Name_Space_name"_"$Operator_pod".log\e[0m"
       fi
     done
   else
    echo -e "$GREEN""No Cluster Operator is in PROGRESSING/DEGRADED state""$NONE"
   fi
   echo "==========================================================================================================================================================="$'\n\n'
   echo -e "\n\e[1;42mMachineConfig Details\e[0m\n************************************************************************"
   omg get mcp
   echo "==========================================================================================================================================================="$'\n\n'
   echo -e "\n\e[1;42mETCD DETAILS Check from NameSpace openshift-etcd\e[0m\n************************************************************************"
   omg get pod -n openshift-etcd | grep -v 'Succeeded'
   echo "==========================================================================================================================================================="$'\n\n'
   echo -e "\n\e[1;42mAPI DETAILS Check from NameSpace openshift-kube-apiserver\e[0m\n************************************************************************"
   omg get pod -n openshift-kube-apiserver | grep -v 'Succeeded'
   echo "==========================================================================================================================================================="$'\n\n'
   echo -n  -e "$RED""Do You want to check Node Wise pod count [Yes/No]:""$NONE"
   read POD_COUNT
   if [ $POD_COUNT == "Yes" ] || [ $POD_COUNT == "YES" ] || [ $POD_COUNT == "yes" ]
    then
     echo -e "\n\e[1;42mPod Count Node wise\e[0m\n************************************************************************"
     for i in `omg get nodes | egrep -v 'NAME' |awk '{print $1}'`; do echo "$i:`omg get pod -A -owide | grep $i|wc -l`"; done
   else
    break
   fi
   echo "==========================================================================================================================================================="$'\n\n'
   echo -e "\n\e[1;42mNot Running Pods from All NameSpaces\e[0m\n************************************************************************"
   omg get pod -A | egrep -v 'Running|Completed|Succeeded'
   echo "==========================================================================================================================================================="$'\n\n'
   echo -e "\n\e[1;42mSecrets per NameSapce\e[0m\n************************************************************************"
   omg get secrets -A | awk '{ns[$1]++}END{for (i in ns) print i,ns[i]}'
   echo "==========================================================================================================================================================="$'\n\n'
   echo -e "\n\e[1;42mList all the configmaps\e[0m\n************************************************************************"
   omg get configmaps
   echo "==========================================================================================================================================================="$'\n\n'
   echo -e "\e[1;42mETCD Analysis\e[0m\n************************************************************************"
   MUST_GATHER_File=`ls $HOME/$CASE_ID/$CHOOSED_MUST_GATHER/ | grep -i must`
   etcd_directory=`find $HOME/$CASE_ID/$CHOOSED_MUST_GATHER/$MUST_GATHER_File/ -type d -name openshift-etcd`
   PV_CHECK_DIR=`find $HOME/$CASE_ID/$CHOOSED_MUST_GATHER/$MUST_GATHER_File/ -type d -name cluster-scoped-resources`
   ETCD_INFO_DIR=`find $HOME/$CASE_ID/$CHOOSED_MUST_GATHER/$MUST_GATHER_File/ -type d -name etcd_info`
   echo -e "\e[1;33mPersistent Volume count:\e[0m `ls $PV_CHECK_DIR/core/persistentvolumes/ |wc -l`"
   echo "++++++++++++++++++++++++++++++++++++++++++++"$'\n'
   echo -e "$RED""etcd DB size""$NONE"
   echo "**********************"
   echo -e "$YELLOW""`cat $ETCD_INFO_DIR/endpoint_status.json |jq '.[].Status|"Revision: " + (.header.revision|tostring) + " | DBsize: " + (.dbSize|tostring) + " DBinuse: " + (.dbSizeInUse|tostring) + " -> Difference: " + ((.dbSize - .dbSizeInUse)/.dbSizeInUse*100|tostring)+"%"'`""$NONE"
   echo "======================================================================================================================================================"$'\n'
   for i in `ls $etcd_directory/pods/ | egrep -v 'pruner|guard|debug'`
    do
     echo $i
     echo "++++++++++++++++++++++++++++++++++++++++++++"
     echo -e "\e[1;33metcd server is likely overloaded messages:\e[0m`cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep 'overload'|wc -l`"
     echo -e "\e[1;33mtook too long messages count:\e[0m `cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep 'took too long'|wc -l`"
     echo -e "\e[1;33mntp clock difference messages count:\e[0m `cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep 'clock difference'|wc -l`"
     echo -e "\e[1;33mfailed to send out heartbeat on time messages count:\e[0m `cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep 'failed to send out heartbeat on time'|wc -l`"
     echo -e "\e[1;33mdatabase space exceeded messages count:\e[0m `cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep 'database space exceeded'|wc -l`"
     echo -e "\e[1;33mleader changed messages count:\e[0m `cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep 'leader changed'|wc -l`"
     if [[ $CL_VERSION = 4.8 ]] || [[ $CL_VERSION > 4.8 ]]
      then
       echo -e "\e[1;33mCompaction highest seconds:\e[0m\n`cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep "compaction"| grep -v downgrade| grep -E "[0-9]+(.[0-9]+)s"|grep -o '[^,]*$'| cut -d":" -f2|grep -oP '"\K[^"]+'|sort| tail -6`"
       echo -e "\e[1;33mCompaction highest ms:\e[0m\n`cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep "compaction"| grep -v downgrade| grep -E "[0-9]+(.[0-9]+)ms"|grep -o '[^,]*$'| cut -d":" -f2|grep -oP '"\K[^"]+'|sort| tail -6`"
     elif [[ $CL_VERSION = 4.7 ]]
      then
       echo -e "\e[1;33mCompaction highest seconds:\e[0m\n`cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep "compaction"| grep -E "[0-9]+(.[0-9]+)s"|cut -d " " -f13| cut -d ')' -f 1 |sort|tail -6`"
       echo -e "\e[1;33mCompaction highest ms:\e[0m\n`cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep "compaction"|grep "compaction"| grep -E "[0-9]+(.[0-9]+)ms"|cut -d " " -f13| cut -d ')' -f 1 |sort|tail -6`"
     else
      echo -e "\e[1;33mCompaction highest seconds:\e[0m\n`cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep "compaction"| grep -E "[0-9]+(.[0-9]+)s"|cut -d " " -f13| cut -d ')' -f 1 |sort|tail -6`"
      echo -e "\e[1;33mCompaction highest ms:\e[0m\n`cat $etcd_directory/pods/$i/etcd/etcd/logs/current.log|grep "compaction"| grep -E "[0-9]+(.[0-9]+)ms"|cut -d " " -f13| cut -d ')' -f 1 |sort|tail -6`"
     fi
     echo "------------------------------------------------------------------------------------------------------------------------------------------------------"
   done
   echo "==========================================================================================================================================================="$'\n\n'
   echo -e "\e[1;42mYou Want to check logs of the pods\e[0m\n*********************************************************************************************************************************"
   while true
   do
   echo -n -e "$RED""Choose [YES/NO]: ""$NONE"
   read OPTION
   if [ $OPTION == "YES" ] || [ $OPTION == "Yes" ] || [ $OPTION == "yes" ]
    then
     echo -n -e "$YELLOW""Provide the NameSpace name: ""$NONE"
     read NS1
     omg get pods -n $NS1
     echo -n -e "$RED""Choose the Pods from the above list: ""$NODE"
     read POD
     omg get pod/$POD -n $NS1 -o json | jq '.spec.containers[].name'
     echo -n -e "$RED""Choose the Container Name from the above: ""$NONE"
     read CONTAINER
     omg logs $POD -c $CONTAINER -n $NS1 > $HOME/$CASE_ID/$NS1-$POD-$CONTAINER.log
     echo "Log File Created $HOME/$CASE_ID/$NS1-$POD-$CONTAINER.log"
     echo -e "$YELLOW""You want to check more logs of pod, Select from below Option""$NONE"
     echo "--------------------------------------------------------------------------------"
   elif [ $OPTION == "NO" ] || [ $OPTION == "No" ] || [ $OPTION == "no" ]
    then
      echo -e "$RED""You have opted for "NO" to end the troubleshooting of logs""$NONE"
      break
   else
    echo -e "$RED""You haven't choose any Option from the above""$NONE"
   fi
   done
   echo "==========================================================================================================================================================="$'\n\n'
   echo -e "\e[1;42mYou Want to check EVENTS\e[0m\n*********************************************************************************************************************************"
   while true
   do
   echo -n -e "$RED""Choose [YES/NO]: ""$NONE"
   read OPTION
   if [ $OPTION == "YES" ] || [ $OPTION == "Yes" ] || [ $OPTION == "yes" ] 
    then
     echo -n -e "$RED""You want to see all the EVENTS(YES) or For Particular NameSpace(NO): ""$NONE"
     read EVENT
     if [ $EVENT == "YES" ] || [ $EVENT == "Yes" ]  || [ $EVENT == "yes" ] 
      then
       echo -n -e "$RED""You want to see all the EVENTS(YES) or want to grep particular error(NO): ""$NONE"
       read ER1
       if [ $ER1 == "YES" ] || [ $ER1 == "Yes" ] || [ $ER1 == "yes" ]
        then
         omg get events -A > $HOME/$CASE_ID/All_Events-log
         echo "Event File created $HOME/$CASE_ID/All_Events-log"
         echo -e "$YELLOW""You want to check more Events, Select from below Option""$NONE"
         echo "--------------------------------------------------------------------------------" 
       else
        echo -n -e "$RED""Give error to grep: ""$NONE"
        read ER2
        omg get events -A | grep -i "$ER2" > $HOME/$CASE_ID/Error_from_all_events-log
        echo "Event File created $HOME/$CASE_ID/Error_from_all_events-log"
        echo "--------------------------------------------------------------------------------"
       fi
     else
      echo -n -e "$RED""Please Provide NameSpace Name: ""$NONE"
      read NS
      echo -n -e "$RED""You want to go for all Error(YES) or want to grep particular Error(NO): ""$NONE"
      read ERROR
      if [ $ERROR == "YES" ] || [ $ERROR == "Yes" ] || [ $ERROR == "yes" ]
       then
        omg get events -n $NS > $HOME/$CASE_ID/$NS-Events-log
        echo "Event File created $HOME/$CASE_ID/$NS-Events-log"
        echo -e "$YELLOW""You want to check more Events, Select from below Option""$NONE"
        echo "--------------------------------------------------------------------------------"
      else
       echo -n -e "$RED""Give error to grep: ""$NONE"
       read ER
       omg get events -n $NS | grep -i "$ER" > $HOME/$CASE_ID/$NS-$ER-Events-log
       echo "Event File of Particular Error is created $HOME/$CASE_ID/$NS-$ER-Events-log"
       echo -e "$YELLOW""You want to check more Events, Select from below Option""$NONE"
       echo "--------------------------------------------------------------------------------"
      fi
     fi
     elif [ $OPTION == "NO" ] || [ $OPTION == "No" ] || [ $OPTION == "no" ]
      then
       echo -e "$RED""You have opted "NO" to end this event check troubleshooting""$NONE"
       break
   else
    echo -e "$RED""You haven't choose any option from the above""$NONE"
   fi
  done
   echo "==========================================================================================================================================================="$'\n\n'

else
 echo -e "$RED Kindly provide the case along side with the script name. Example: ./must_gather_check.sh <case_number> $NONE"
fi