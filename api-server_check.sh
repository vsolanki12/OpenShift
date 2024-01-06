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
   echo -e "\n\e[1;44m $CHOOSED_MUST_GATHER File used for this output \e[0m"
   echo "*************************************************************************"
   omc use $HOME/$CASE_ID/$CHOOSED_MUST_GATHER > $HOME/must-gather-used.txt
   echo -e "\n\e[1;42mCluster Infrastructure Check\e[0m\n*********************************************"
   echo -e "$YELLOW""Platform Type:`omc get infrastructure/cluster -o json | jq '.spec.platformSpec.type'`""$NONE"
   echo -e "$YELLOW""Cluster ID:""$NONE"`omc get clusterversion -o json | jq '.items[].spec.clusterID'`
   echo "==========================================================================================================================================================="$'\n\n'
   echo -e "\n\e[1;46mCluster version\e[0m:\n `omc get clusterversion`" 
   CL_VERSION=`omc get clusterversion|awk '{print $2}' | grep -v VERSION|awk -F'.' '{print $1"."$2}'`
   echo "==========================================================================================================================================================="$'\n\n'
   echo -e "\n\e[1;46mCluster API URL\e[0m"
   echo "*********************************************************************************"
   omc get infrastructure -ojson| jq '.items[].status.apiServerURL'
   echo "==========================================================================================================================================================="$'\n\n'
   echo -e "\n\e[1;46mCluster Master Node Memory & Cpu Capacity\e[0m"
   echo "*********************************************************************************"
   echo "Node | Cpu | Memory"
   echo "+++++++++++++++++++++++++++++++"
   for master in `omc get nodes | grep -i master | awk '{print $1}'`
    do
     echo "$master|`omc get nodes $master -ojson|jq -r '.status.capacity| "\(.cpu)|\(.memory)"'`"
   done
   echo "==========================================================================================================================================================="$'\n\n'
   echo -e "\n\e[1;42mAPI DETAILS Check from NameSpace openshift-kube-apiserver\e[0m\n************************************************************************"
   omc get pod -n openshift-kube-apiserver | egrep -iv 'revision|installer'
   echo "==========================================================================================================================================================="$'\n\n'
   echo -e "\n\e[1;42mChecking the ETCD Encryption is enabled or not\e[0m\n************************************************************************"
   ENCRYPTION=`omc get apiserver cluster -ojson | jq '.spec.encryption.type' | tr -d '"'`
   if [ $ENCRYPTION == "aescbc" ]
    then
     echo "ETCD encryption is enabled"
     omc get apiserver cluster -ojson | jq '.spec.encryption'
   else
    echo "ETCD encryption is not enabled"
   fi
   echo "==========================================================================================================================================================="$'\n\n'
   echo -e "\n\e[1;42mSecret details from NameSpace openshift-kube-apiserver\e[0m\n************************************************************************"
   echo "Total Number of Secrets:`omc get secrets -n openshift-kube-apiserver|grep -v NAME |awk '{print $1}' |wc -l`" 
   echo "Segregation of Secrets"
   omc get secrets -n openshift-kube-apiserver|grep -v NAME |awk '{print $1}' | awk '{print $0}' |  awk -F'-' 'BEGIN {OFS="-"} {$NF=""} 1' | sort | uniq -c | sort -rn|sed 's/-$//'
   echo "==========================================================================================================================================================="$'\n\n'
else
 echo -e "$RED Kindly provide the case along side with the script name. Example: ./must_gather_check.sh <case_number> $NONE"
fi

