# OpenShift
**NOTE: ONLY FOR RED HAT TEAM USE**


**This Repository containing the must-gather & sos-report analysis & ETCD took too long count check date wise scripts which we can use from the Support Shell.**

**Usage of the Must-Gather script** 
~~~
sh new_must_gather.sh <Case-id>

Then it will ask for the Must-Gather input file. 
**EXAMPLE:**
$ sh new_must_gather.sh <Case-id>
drwxrwxrwx. 3 yank     yank            59 May 12 17:55 0030-must-gather.tar.gz
drwxrwxrwx. 3 yank     yank            59 May 13 11:19 0050-must-gather.tar.gz
drwxrwxrwx. 3 yank     yank          4096 May 17 07:10 0070-must-gather.tar.gz
-rw-rw-rw-. 1 vsolanki vsolanki        95 Jun 11 07:23 Kubelet_Restart_Error.log
Choose the must-gather from the above output:
~~~
**IMPORTANT NOTE: This Script is using omg tool in the background.**   
**IMPORTANT FILE** for Cluster Operator check in this Script is --> **CO_NS.txt** (This File Contains the Cluster Operator and NameSpaces.)
    
**Once you choosed the file it will print all the required details of basic checks. What I have included as of the on the script details are below:**
~~~
    1. Platform Type
    2. Network Details 
    3. Cluster Version
    4. Upgrade History with Date
    5. Node Type count & Total Node count
    6. You want to list all nodes or not want to list
    7. Node Annotations if you want to check if yes it will generate the log file.
    8. Control plane pod revisions of ETCD, Kube-apiserver, Kube-controller-manager, & Kube-scheduler
    9. Node NotReady List
    10. Cluster Operator which are in PROGRESSING/DEGRADED state. If found any capture the operator logs.
    11. MCP Output
    12. ETCD pods status from etcd namespace
    13. Kube-apiserver pods status form apiserver namespace
    14. You want to check the node wise pod count. It will provide you the option.
    15. List all not running pods from all NameSpaces.
    16. Secrets count per namespace
    17. List Configmaps 
    18. Persistent Volume count
    19. ETCD DBsize
    20. ETCD error logs count (Overloaded, took too long, ntp clock difference, failed to send heartbeat, leader change, database exceed, & compaction rate in seconds & milliseconds) for all master.
    21. If you want to check logs for any particular NameSpace.
    22. If you want to check Events for any particular NameSpace.
   
 
  This Must-Gather Script will help you to fast track some basics sanity checks of must-gather.
~~~    
   
**Usage of the SOS-Report script**
~~~
sh sos-report-check.sh <case-id>

Then it will ask for the SOS-Report input file. 
**EXAMPLE:**  
$ sh sos-report-check.sh <Case-id>
drwxrwxrwx. 3 yank     yank            95 Jun 11 07:21 0020-sosreport-2022-05-12-jhmrcxh.tar.xz
drwxrwxrwx. 3 yank     yank            70 May 17 07:00 0060-sosreport-2022-05-17-vmbhhey.tar.xz
Choose the sos-report from the above output:
~~~

**Once you choosed the file it will print all the required details of basic checks. What I have included as of the on the script details are below:**
 ~~~
    1. Hostname of the node
    2. Uptime of the node
    3. Kernel Version
    4. Red Hat Release
    5. H/W details 
    6. Kdump enabled or disabled status
    7. XSOS Output or memory, cpu, Zombie, & Utilization processes.
    8. Free file output
    9. Print File System which are more than 70%.
    10. OOM Killer messages and create logs file.
    11. Node not found error and create logs file.
    12. TLS Handshake error and create logs file. 
    13. No such network interface error and create logs file. 
    14. Node NotReady error and create logs file. 
    15. Kubelet Restart error and create logs file. 
    16. Kubelet NotReady error and create logs file. 
    17. PLEG not healthy error and create logs file. 
    18. Orphan pod error and create logs file. 
    19. Give option to list the orphan pods id
    20. CRI-O Panic error and create logs file. 
    21. Reebot count of node and provide time of last reboot only.
    22. Intentional reboot count of node and provide time of last reboot only.
    23. dmesg file path

 This SOS-report Script will help you to fast track some basics sanity checks from the sos-report.
~~~

**Usage of the etcd_ttl script**    
~~~
sh etcd_ttl.sh <Case-id>

It will provide the details of took too long messages count date wise per master from the must-gather logs. 
**EXAMPLE:**
$ sh etcd_ttl.sh <Case-id>
drwxrwxrwx. 3 yank     yank           59 May 12 17:55 0030-must-gather.tar.gz
drwxrwxrwx. 3 yank     yank           59 May 13 11:19 0050-must-gather.tar.gz
drwxrwxrwx. 3 yank     yank         4096 May 17 07:10 0070-must-gather.tar.gz
Choose the must-gather from the above output:0070-must-gather.tar.gz

took too long messages date & time wise count <ETCD-MASTER-HOSTNAME> 2022-05-15
more than 100ms:3373
more than 200ms:1114
more than 300ms:286
more than 400ms:163
more than 500ms:119
more than 600ms:75
more than 700ms:54
more than 800ms:37
more than 900ms:20
more than 1s:119
more than 2s:82
more than 3s:50
more than 4s:3
~~~
