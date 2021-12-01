#!/usr/bin/env bash
################################################################################
# This scripts is helpful in Bi-directional sync using Unison tool
# Unison: 
# https://www.cis.upenn.edu/~bcpierce/unison/download/releases/stable/unison-manual.html
#
# This Scripts takes 2 inputs as command line
#   1. NFS Path - Used to create a lock so that the the script is not syncing
#      with the same server in same Data-Center (2 Server are sharing same NFS)
#   2. ServerList - A file which has data about the servers to which the script
#      will be syncing with - This supports more than 2 Data Center.
#
# e.g. sh syncScript.sh /NFS_PATH ServerList
# ServerList:
#        DC1=myserver.example.com,myserver2.example.com
#        DC2=myserver3.example.com
#        DC3=myserver4.example.com
#
# Github URL:
# https://github.com/nurawat/unison
#
################################################################################

# Getting Command Line Arguments in Place
unison_lock_folder_path=${1:-"ERROR: Must Specify the Directory Path for NFS"}
server_list=${2:-"ERROR: Must Specify the Server List"}

# Global Variables
declare -A servers_list reachable
declare -a dc_list

# Script directory and workspace can be different
__SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly __SCRIPT_DIR

# System Command
_unison=/usr/bin/unison
host_name=$(hostname)

# Custom Variables
time_stamp=$(date +%Y-%m-%d)
time_stamp_all=$(date +%Y-%m-%d-[%H:%M:%S])
log_folder="${__SCRIPT_DIR}/unison_logs"
log_file="${log_folder}/unison_sync_${time_stamp}.log"
keep_logs_in_days=2

lock_file="${unison_lock_folder_path}/unison.lock"
mail_id="MY_EMAIL_ID@<Domain>.com"
cleanUpNeeded=false

# If Log folder doesn't exist try creating one
if ! [ -d "${log_folder}" ]; then
  mkdir ${log_folder}
fi

# Ensure workspace deletion on EXIT
function cleanUp {
  if $cleanUpNeeded ; then
    rm -f "${lock_file}"
  fi
}
trap cleanUp EXIT

function usage {
  echo -e "Usage Guide"
  echo -e "sh syncScript.sh Options"
  echo -e "\t Parameters:"
  echo -e "\t Unison Lock Folder Path e.g. /IDK"
  echo -e "\t Server List - File which will have Entry for the DC"
  echo -e "\t\t server.txt -"
  echo -e "DC1=myserver.example.com,myserver2.example.com"
  echo -e "DC2=myserver3.example.com"
  echo -e "DC3=myserver4.example.com"
}

function checkLock {
  echo "[INFO]: Checking Lock -If already exists I will skip, My assosicate is doing the Job !!!"
  touch ${log_file}
  if [ -f "${lock_file}" ]; then
    echo "[INFO] - ${time_stamp_all}: SKIPPING Synchronization - Lock Found !!!, Script is already running." >> ${log_file}
    exit 1
  else
    touch ${lock_file}
    cleanUpNeeded=true
  fi
}

function validateInputs {
  echo "[INFO]: Validating Inputs !!!"
  if ! [ -d "${unison_lock_folder_path}" ]; then
    echo "[ERROR] - Invalid NFS Share Path !!!, Path doesn't exists !!!"
    usage
    exit 2
  fi

  if ! [ -f "${server_list}" ]; then
    echo "[ERROR] - Invalid ServerList Path !!!, File doesn't exists !!!"
    usage
    exit 3
  fi
}


function deleteOldLogs {
  if find ${log_folder} -mtime +${keep_logs_in_days} -type f -delete &>/dev/null; then
    echo "[INFO]: Deleting Logs Older than ${keep_logs_in_days} Days !!!"
  fi
}

function readServerList {
  echo "[INFO]: Reading the Values from Command lines and Assosicated files !!!"
  local dc
  while read line; do
    dc=$(echo ${line} | cut -d= -f1)
    sl=$(echo ${line} | cut -d= -f2- | egrep -v $host_name)
    
    if ! [ -z $sl ]; then
      servers_list[$dc]=$sl
      dc_list=(${dc_list[@]} $dc)
    fi
  done < ${server_list}
}

function report_error {
  echo "[INFO]: Something Went Wrong, I am Reporting the Issue !!!"
  mail -s "Synchronization failed on $(hostname)" ${mail_id}
}

function printLog {
  if [ $3 == 0 ]; then
    echo "[INFO] - ${time_stamp_all}: SUCCESS Synchronization - Folder: $1, Server ${2}; Everything is UP-TO-DATE Now." >> ${log_file}
  else
    echo "[INFO] - ${time_stamp_all}: FAILED Synchronization - Folder: $1, Server ${2}; Something Went Wrong." >> ${log_file}
    report_error
    exit 8
  fi
}

function syncServer {
  echo "[INFO]: Synchronizing the Folders, I will report if something goes wrong !!!"

  local -a getDestinationServer failed_list

  syncFlag=0
  directory_paths="/some/folder/path/
        /some/folder/paths
        /some/folder/pathss

  for dc in ${dc_list[@]}; do
    getDestinationServer=($(echo ${servers_list[$dc]} | tr "," "\n"))
    getServerConnectionCount=0
    for server in ${getDestinationServer[@]}; do
      failedSync=true
      ${_unison} -silent -testserver test ssh://${server}/ &>/dev/null
      if [ $? == 0 ]; then
        failedSync=false
        for folder in ${directory_paths[@]}; do
          ${_unison} -confirmbigdel=false -batch -silent ${folder} ssh://${server}/${folder}
          if [ $? == 3 ]; then
              printLog $folder $server 1
          else
              printLog $folder $server 0
          fi
        done
        getServerConnectionCount=$((getServerConnectionCount+1))
      else
        failed_list=(${failed_list[@]} $server)
      fi

      if ! $failedSync; then
        break
      fi
    done
    
    if [[ ${#failed_list[@]} == ${#getDestinationServer[@]} ]]; then
      echo "[ERROR] - ${time_stamp_all}: FAILED Synchronization - Servers not Reachable - $(echo ${failed_list[@]} | tr "\n" ",") from $host_name" >> ${log_file}
    else
      syncFlag=$((syncFlag+1))
    fi
  done

  if [[ ${syncFlag} == ${#dc_list[@]} ]]; then
    echo "====> [INFO]  - ${time_stamp_all}: SUCCESSFUL Synchronization - ALL the files and folder were sync'd" >> ${log_file}
  else
    echo "[ERROR] - ${time_stamp_all}: FAILED Synchronization - Some Folder's failed to synchronize" >> ${log_file}
  fi
}

# THIS IS THE CALLING OUT FOR EACH FUNCTION DESCRIBED ABOVE
# This is just a Script Holder or Display Message about the script that is going
# to get executed.
cat <<EOM
[]------------------------- SYNC AUTOMATED SCRIPT -----------------------------[]
|                                                                              |
                This Script for File Sync Between Servers                      
|                                                                              |
[]-------------------------- SCRIPT VERSION - 1.0.0 ---------------------------[]
Stakeholders:
  RawatArun65@GMAIL.com

Acronyms:
[INFO] - [INFORMATION]: Related to What the Script is Doing
[ERR]  - [ERROR] - Mostly Because Script is Given Wrong Inputs
[END]  - [END: Script executing end

[NOTE]: Report any in-appropriate/Bug with StakeHolders.

[]--------------------------SCRIPT EXECUTION STARTS HERE----------------------[]
EOM


# All logic Starts Here
checkLock
validateInputs
deleteOldLogs
readServerList
syncServer
echo "[END] - I am Done Executing !!!"
