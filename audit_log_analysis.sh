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
   echo -e -n "\e[1;43mChoose the audit log must-gather from the above output:\e[0m"
   read CHOOSED_MUST_GATHER
   MUST_GATHER_File=`ls $HOME/$CASE_ID/$CHOOSED_MUST_GATHER/ | grep -i must`
   QUAY_PATH=`ls $HOME/$CASE_ID/$CHOOSED_MUST_GATHER/$MUST_GATHER_File/ | grep -i quay`
   KUBE_APISERVER_LOG_PATH=`ls $HOME/$CASE_ID/$CHOOSED_MUST_GATHER/$MUST_GATHER_File/$QUAY_PATH/audit_logs/kube-apiserver | grep -i audit | awk -F'audit' '{print $1}'|sort|uniq`
   echo $KUBE_APISERVER_LOG_PATH
   for i in $KUBE_APISERVER_LOG_PATH
    do
     AUDIT_LOG_FILE_NAME=`echo $i | sed 's/-$//g'`
     echo "$AUDIT_LOG_FILE_NAME top 10 NameSpace audit call"
     echo "*****************************************************"
     zcat $HOME/$CASE_ID/$CHOOSED_MUST_GATHER/$MUST_GATHER_File/$QUAY_PATH/audit_logs/kube-apiserver/$AUDIT_LOG_FILE_NAME-audit* |jq .objectRef.namespace -r | sort | uniq -c | sort -nr | head
     echo "================================================================================================================================================================"
     echo "$AUDIT_LOG_FILE_NAME top 10 Users audit call"
     echo "*****************************************************"
     zcat $HOME/$CASE_ID/$CHOOSED_MUST_GATHER/$MUST_GATHER_File/$QUAY_PATH/audit_logs/kube-apiserver/$AUDIT_LOG_FILE_NAME-audit* |jq .user.username -r | sort | uniq -c | sort -rn|head
     echo "================================================================================================================================================================"
     echo "$AUDIT_LOG_FILE_NAME top 10 Request URI calls"
     echo "*****************************************************"
     zcat $HOME/$CASE_ID/$CHOOSED_MUST_GATHER/$MUST_GATHER_File/$QUAY_PATH/audit_logs/kube-apiserver/$AUDIT_LOG_FILE_NAME-audit* |jq .requestURI |awk  'BEGIN{FS="/"; OFS="/";} /^\"/{print $2,$3,$4,$5,$6}' | sort | uniq -c | sort -nr | head
     echo "================================================================================================================================================================"
     echo "$AUDIT_LOG_FILE_NAME Total Number of Calls date wise"
     echo "*****************************************************"
     zcat $HOME/$CASE_ID/$CHOOSED_MUST_GATHER/$MUST_GATHER_File/$QUAY_PATH/audit_logs/kube-apiserver/$AUDIT_LOG_FILE_NAME-audit* |jq '.requestReceivedTimestamp' | awk -F'T' '{print $1}'| tr -d '"'  | sort | uniq -c | sort -rn
     echo "================================================================================================================================================================"
     echo "$AUDIT_LOG_FILE_NAME Total Number of Calls hour wise"
     echo "*****************************************************"
     zcat $HOME/$CASE_ID/$CHOOSED_MUST_GATHER/$MUST_GATHER_File/$QUAY_PATH/audit_logs/kube-apiserver/$AUDIT_LOG_FILE_NAME-audit* |jq '.requestReceivedTimestamp' | awk -F':' '{print $1}'| tr -d '"'  | sort | uniq -c | sort -rn 
     echo "================================================================================================================================================================"
   done
else
 echo -e "$RED Kindly provide the case along side with the script name. Example: ./must_gather_check.sh <case_number> $NONE"
fi
