#!/bin/bash
#!/bin/sh
if [ $# == 1 ]
 then
  CASE_DIR=$1
  echo -e "`ls -l $HOME/$CASE_DIR/ | grep sos|egrep 'gz|xz|zip'`"
  echo -e -n "\e[1;43mChoose the sos-report from the above output:\e[0m"
  read SOS_DIR
  SOS_Final=`ls $HOME/$CASE_DIR/$SOS_DIR/`
  echo -e "\e[1;43mChecking System Level Infromation \e[0m"
  echo "===================================================================================="$'\n'
  echo -e "\e[1;31mHostname\e[0m"
  echo "----------------------------"
  cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/hostname 
  echo ""
  echo -e "\e[1;31mUptime\e[0m"
  echo "----------------------------"
  cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/uptime
  echo ""
  echo -e "\e[1;31mKernel Version\e[0m"
  echo "----------------------------"
  cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/uname
  echo ""
  echo -e "\e[1;31mRedhat Release\e[0m"
  echo "----------------------------"
  cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/etc/redhat-release
  echo ""
  echo -e "\e[1;31mSystem Information\e[0m"
  echo "------------------------------"
  cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/dmidecode | grep -A2 "System Information"
  echo ""
  echo -e "\e[1;31mKdump(Kernel) Information about enabled or disabled\e[0m"
  echo "--------------------------------------------------------------------------"$'\n'
  cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/systemd/systemctl_list-unit-files | grep kdump
  echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"$'\n\n'
  echo -e "\e[1;43m Checking Memory CPU and Processes \e[0m"
  echo "===================================================================================="$'\n'
  xsos -c -m -o -p $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final
  echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"$'\n\n'
  echo -e "\e[1;43m Checking Memory from "free file" \e[0m"
  echo "===================================================================================="$'\n'
  cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/free
  echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"$'\n\n'
  echo -e "\e[1;43m Checking the File System which are greater than 70% \e[0m"
  echo "-----------------------------------------------------------"$'\n'
  count=`cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/df | egrep "([70,80,90][0-9]|100)%"|wc -l`
  if [ $count -eq 0 ]
   then
    echo -e "\e[01;32m No Filesystem greater than 70%\e[0m"
  else
    cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/df | egrep "([70,80,90][0-9]|100)%"
  fi
  echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"$'\n\n'
  ######## Checking the OOM Killer Alarm from the SOS report ####################
    
  echo -e "\e[1;43m Checking the OOM Killer Alarm from the SOS report \e[0m"
  echo "-----------------------------------------------------------"$'\n'
  JOURNAL_DIR=`ls $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/var/log/journal/`
  OOM_CHECK=`journalctl --file $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/var/log/journal/$JOURNAL_DIR/system.journal|grep -Ei "oom-killer|Out of memory" |wc -l`
  if [ $OOM_CHECK -eq 0 ]
   then
    echo -e "\e[01;32m No latest OOM Killer Messages\e[0m"
  else
    echo -e "\e[1;31mTotal OOM Killer logs\e[0m="$OOM_CHECK
    echo -e "\e[1;31m`journalctl --file $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/var/log/journal/$JOURNAL_DIR/system.journal|grep -Ei "oom-killer|Out of memory"|tail -3`\e[0m"
    for file in $(ls -1tr $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/var/log/journal/$JOURNAL_DIR/system*.journal); do echo -e "\n$file\n=============================="; journalctl --file $file|grep -Ei "oom-killer|Out of memory"; done > $HOME/$CASE_DIR/OOM_KIller.log
    echo -e "\e[1;35mLog File Created at $HOME/$CASE_DIR/OOM_KIller.log\e[0m"
  fi
  echo "=========================================================================================================================================================="$'\n'
  echo -e "\e[1;43m Checking the Kubelet Errors from the SOS report \e[0m"
  echo "-----------------------------------------------------------"$'\n'
  HST_NAME=`cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/hostname`
  HST_NAME_NOT_FOUND=`cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/openshift/journalctl_--no-pager_--unit_kubelet | grep 'node "'$HST_NAME'" not found'|wc -l`
  if [ $HST_NAME_NOT_FOUND -eq 0 ]
   then
    echo -e "\e[01;32m No Error of node $HST_NAME not found\e[0m"
  else
    echo "node $HST_NAME not found error=$HST_NAME_NOT_FOUND"
    echo "---------------------------------------------------------------"
    echo -e "\e[01;31m`cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/openshift/journalctl_--no-pager_--unit_kubelet | grep 'node "'$HST_NAME'" not found'|tail -3`\e[0m"
    cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/openshift/journalctl_--no-pager_--unit_kubelet | grep 'node "'$HST_NAME'" not found' > $HOME/$CASE_DIR/Node_Not_Found_Error.log
    echo -e "\e[01;35mLog File Created at $HOME/$CASE_DIR/Node_Not_Found_Error.log\e[0m"
  fi
  echo "=========================================================================================================================================================="$'\n'
  TLS_HANDSHAKE=`cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/openshift/journalctl_--no-pager_--unit_kubelet | grep "TLS handshake error" |wc -l`
  if [ $TLS_HANDSHAKE -eq 0 ]
   then
    echo -e "\e[01;32m No Error of TLS Handshake\e[0m"
  else
    echo "TLS Handshake error=$TLS_HANDSHAKE"
    echo "------------------- "
    echo -e "\e[1;31m`cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/openshift/journalctl_--no-pager_--unit_kubelet | grep "TLS handshake error" |tail -3`\e[0m"
    cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/openshift/journalctl_--no-pager_--unit_kubelet | grep "TLS handshake error" > $HOME/$CASE_DIR/TLS_Handshake_Error.log
    echo -e "\e[01;35mLog File Created at $HOME/$CASE_DIR/TLS_Handshake_Error.log\e[0m"
  fi
  echo "=========================================================================================================================================================="$'\n'
  NO_NET=`cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/openshift/journalctl_--no-pager_--unit_kubelet | grep "kubelet_node_status.go"  | grep "no such network interface"|wc -l`
  if [ $NO_NET -eq 0 ]
   then
    echo -e "\e[01;32m No Error of no such network interface\e[0m"
  else
    echo "No such Network Interface Error=$NO_NET"
    echo "---------------------------------"
    echo -e "\e[01;31m`cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/openshift/journalctl_--no-pager_--unit_kubelet | grep "kubelet_node_status.go"  | grep "no such network interface" |tail -3`\e[0m"
    cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/openshift/journalctl_--no-pager_--unit_kubelet | grep "kubelet_node_status.go"  | grep "no such network interface" > $HOME/$CASE_DIR/No_Network_Interface_Error.log
    echo -e "\e[01;35mLog File Created at $HOME/$CASE_DIR/No_Network_Interface_Error.log\e[0m"
  fi
  echo "=========================================================================================================================================================="$'\n'  
  NOT_READY=`cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/openshift/journalctl_--no-pager_--unit_kubelet | grep "kubelet_node_status.go"  | grep "NodeNotReady" |wc -l`
  if [ $NOT_READY -eq 0 ]
   then
    echo -e "\e[01;32m No Error of NodeNotReady\e[0m"
  else
    echo "NodeNotReady Error=$NOT_READY"
    echo "---------------------------------"
    echo -e "\e[01;31m`cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/openshift/journalctl_--no-pager_--unit_kubelet | grep "kubelet_node_status.go"  |grep "NodeNotReady" |tail -3`\e[0m"
    cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/openshift/journalctl_--no-pager_--unit_kubelet | grep "kubelet_node_status.go"  |grep "NodeNotReady" > $HOME/$CASE_DIR/Node_NotReady_Error.log
    echo -e "\e[01;35mLog File Created at $HOME/$CASE_DIR/Node_NotReady_Error.log\e[0m"
  fi
  echo "=========================================================================================================================================================="$'\n'
  KUBELET_NOTREADY=`cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/openshift/journalctl_--no-pager_--unit_kubelet  |grep -i "KubeletNotReady"|wc -l`
  if [ $KUBELET_NOTREADY -eq 0 ]
   then
    echo -e "\e[01;32m No Error of KubeletNotReady\e[0m"
  else
    echo "Kubelet Restart Error=$KUBELET_NOTREADY"
    echo "---------------------------------"
    echo -e "\e[01;31m`cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/openshift/journalctl_--no-pager_--unit_kubelet  |grep -i "Stopped Kubernetes Kubelet"|tail -3`\e[0m"
    cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/openshift/journalctl_--no-pager_--unit_kubelet  |grep -i "Stopped Kubernetes Kubelet" > $HOME/$CASE_DIR/Kubelet_Restart_Error.log
    echo -e "\e[01;35mLog File Created at $HOME/$CASE_DIR/Kubelet_Restart_Error.log\e[0m"
    echo "**************************************************************************************************************************************************"
    echo "KubeletNotReady Error"
    echo "---------------------------------"
    echo -e "\e[01;31m`cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/openshift/journalctl_--no-pager_--unit_kubelet  |grep -i "KubeletNotReady"|tail -3`\e[0m"
    cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/openshift/journalctl_--no-pager_--unit_kubelet  |grep -i "KubeletNotReady"> $HOME/$CASE_DIR/Kubelet_NotReady_Error.log
    echo -e "\e[01;35mLog File Created at $HOME/$CASE_DIR/Kubelet_NotReady_Error.log\e[0m"
  fi
  echo "=========================================================================================================================================================="$'\n'
  PLEG_ISSUE=`cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/openshift/journalctl_--no-pager_--unit_kubelet  | grep "kubelet.go" | grep "PLEG is not healthy" |wc -l`
  if [ $PLEG_ISSUE -eq 0 ]
   then
    echo -e "\e[01;32m No Error of PLEG is not healthy\e[0m"
  else
    echo "PLEG is not healthy Error=$PLEG_ISSUE"
    echo "---------------------------------"
    echo -e "\e[01;31m`cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/openshift/journalctl_--no-pager_--unit_kubelet  | grep "kubelet.go" | grep "PLEG is not healthy"|tail -3`\e[0m"
    cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/openshift/journalctl_--no-pager_--unit_kubelet  | grep "kubelet.go" | grep "PLEG is not healthy" > $HOME/$CASE_DIR/PLEG_NotHealthy_Error.log
    echo -e "\e[01;35mLog File Created at $HOME/$CASE_DIR/PLEG_NotHealthy_Error.log\e[0m"
  fi
  echo "=========================================================================================================================================================="$'\n'
  ORPHAN_POD=`cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/openshift/journalctl_--no-pager_--unit_kubelet  | grep "orphaned pod"|wc -l`
  if [ $ORPHAN_POD -eq 0 ]
   then
    echo -e "\e[01;32m No orphan pod error\e[0m"
  else
    echo -e "\e[01;31mTotal Orphan pod error Count=`cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/openshift/journalctl_--no-pager_--unit_kubelet  | grep "orphaned pod" |wc -l`\e[0m"
    echo "Last 3 Orphan pod errors"
    echo "----------------------------------"
    echo -e "\e[01;31m`cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/openshift/journalctl_--no-pager_--unit_kubelet  | grep "orphaned pod"| tail -3`\e[0m"
    cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/openshift/journalctl_--no-pager_--unit_kubelet  | grep "orphaned pod" > $HOME/$CASE_DIR/Orphan_Pod_Error.log
    echo -e "\e[01;35mLog File Created at $HOME/$CASE_DIR/Orphan_Pod_Error.log\e[0m"
    echo "*******************************************************************************************************************************************************"$'\n'
    echo -e -n "\e[01;32mDo you want to print all the orphan pod uid[YES/NO] :\e[0m"
    read input
    if [ $input == "YES" ]
     then
      cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/openshift/journalctl_--no-pager_--unit_kubelet  | grep "orphaned pod"| awk -F'=' '{print $2}'|awk '{print $1}'|sort|uniq > $HOME/$CASE_DIR/Orphan_pod_uid_list.log
      echo -e "\e[01;35mLog File Created at $HOME/$CASE_DIR/Orphan_pod_uid_list.log\e[0m"
   else [ $input == "NO" ]
    break
   fi
  fi
  echo "=========================================================================================================================================================="$'\n'
  NAME_RESERVED=`cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/openshift/journalctl_--no-pager_--unit_kubelet  | grep "name is reserved" |wc -l`
  if [ $NAME_RESERVED -eq 0 ]
   then
    echo -e "\e[01;32m No name is reserved error\e[0m"
  else
    echo -e "\e[01;31mTotal no name is reserved error Count=`cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/openshift/journalctl_--no-pager_--unit_kubelet  | grep "name is reserved" |wc -l`\e[0m"
    echo "Last 3 no name is reserved errors"
    echo "----------------------------------"
    echo -e "\e[01;31m`cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/openshift/journalctl_--no-pager_--unit_kubelet  | grep "name is reserved"|tail -3`\e[0m"
    cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/openshift/journalctl_--no-pager_--unit_kubelet  | grep "name is reserved" > $HOME/$CASE_DIR/Name_Reserved_Error.log
    echo -e "\e[01;35mLog File Created at $HOME/$CASE_DIR/Name_Reserved_Error.log\e[0m"
   fi
   echo "=========================================================================================================================================================="$'\n'
  CRIO_PANIC=`cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/logs/journalctl_--no-pager|grep -i "panic: close of closed channel"|wc -l`
  if [ $CRIO_PANIC -eq 0 ]
   then
    echo -e "\e[01;32m No Error of CRI-O Panic\e[0m"
  else
   echo "CRI-O Panic Error=$CRIO_PANIC"
   echo "-----------------------------"
   echo -e "\e[01;31m`cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/logs/journalctl_--no-pager|grep -i "panic: close of closed channel"|tail -3`\e[0m"
   cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/logs/journalctl_--no-pager|grep -i "panic: close of closed channel" > $HOME/$CASE_DIR/Crio_Panic.log
   echo -e "\e[01;35mLog File Created at $HOME/$CASE_DIR/Crio_Panic.log\e[0m"
  fi
  echo "=========================================================================================================================================================="$'\n'
  echo -e "\e[1;43m Checking the Reboot of node from the journalctl_--no-pager logs \e[0m"
  echo "---------------------------------------------------------------------------------------"$'\n'
  REBOOT_COUNT=`cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/logs/journalctl_--no-pager| grep '\-- Reboot\b'|wc -l`
  if [ $REBOOT_COUNT -eq 0 ]
   then
    echo -e "\e[01;32m No Reboot error found in the logs\e[0m"
  else
   echo "Total Reboot Count=$REBOOT_COUNT"
   echo -e "\e[01;31m`cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/logs/journalctl_--no-pager| grep '\-- Reboot\b'|tail -3`\e[0m"
   echo "*******************************************************************************************"
   echo "Last reboot details(For more details check $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/logs/journalctl_--no-pager file)"
   echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
   LAST_REBOOT_MORE=`cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/logs/journalctl_--no-pager| grep -n '\-- Reboot\b'|tail -1|awk -F':' '{print $1}'`
   LAST_LINE=` expr $LAST_REBOOT_MORE + 10 `
   echo -e "\e[01;31m`sed -n "$LAST_REBOOT_MORE,${LAST_LINE} p" $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/logs/journalctl_--no-pager`\e[0m"
  fi
  echo "=========================================================================================================================================================="$'\n'
  echo -e "\e[1;43m Finding the Last Reboot of node from the journalctl_--no-pager logs was Intentional \e[0m"
  echo "--------------------------------------------------------------------------------------------------"$'\n'
  INTENT_REBOOT=`cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/logs/journalctl_--no-pager| grep "Starting Reboot..."|wc -l`
  if [ $INTENT_REBOOT -eq 0 ]
   then
    echo -e "\e[01;32m No Intentional Reboot error found in the logs\e[0m"
  else
   echo "Intent Reboot Count=$INTENT_REBOOT"
   CHECK_REBOOT_LINE=`cat $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/logs/journalctl_--no-pager| grep -n "Starting Reboot"|tail -1|awk -F':' '{print $1}'`
   LAST_REBOOT_LINE=` expr $CHECK_REBOOT_LINE + 12 `
   echo "This is the last reboot given intentionaly"
   echo "++++++++++++++++++++++++++++++++++++++++++++++++++"
   echo -e "\e[01;31m`sed -n "$CHECK_REBOOT_LINE,${LAST_REBOOT_LINE}p" $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/sos_commands/logs/journalctl_--no-pager`\e[0m"
  fi
  echo "=========================================================================================================================================================="$'\n'
  echo -e "\e[01;34mYou can check the dmesg file in case reboot(path of file is `find $HOME/$CASE_DIR/$SOS_DIR/$SOS_Final/ -type f -name "dmesg*"`)\e[0m"
  echo "=========================================================================================================================================================="$'\n'
else
  echo -e "\e[1;31mKindly provide the case along side with the script name. Example ./sos-report-check.sh case_number\e[0m"
fi
