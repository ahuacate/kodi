#!/bin/ash

################################################################
# This script is to Rsync a CoreElec host                      #
# local USB Hard Disk with a NAS.                              #
#                                                              #
# Tested on : CoreELEC (official): 9.2.1 (Amlogic-ng.arm)      #
################################################################

#####################VARIABLES DEFINED##########################

NAS_TYPE="<insert here>"

NAS_IP="<insert here>"

SSH_PORT="<insert here>"
RSYNC_SSH_PORT="<insert here>"

USER_BASE_DIR="<insert here>"
SOURCE_BASE_DIR="<insert here>"

SOURCE_DIR="<insert here>"
DESTINATION_DIR="/var/media/remote/"

LOCAL_DIR="<insert here>"

INPUT_LIST="/var/media/remote/logs/rsync_input.list.txt"

LOGFILE=/var/media/remote/logs/kodi_rsync_daily.log
LOGFILE_ERRORS=/var/media/remote/logs/kodi_rsync_errors.log

NAS_LINK=$(ethtool eth0 | grep "Link detected: yes" > /dev/null; echo $?)

if [ "$NAS_LINK" == 0 ]; then
  NAS_PING=$(ping -s 1 -c 2 "$NAS_IP" > /dev/null; echo $?)
else
  NAS_PING=1
fi

MOUNT_CHECK=$(df | grep -q '/var/media/remote' > /dev/null; echo $?)

################################################################

# Download external scripts
#wget -q https://raw.githubusercontent.com/ahuacate/kodi/master/scripts/coreelec_kodi_rsync_script.sh -O /storage/.config/scripts/coreelec_kodi_rsync_script.sh


if [ "$NAS_LINK" == 0 ] && [ "$NAS_PING" == 0 ] && [ "$MOUNT_CHECK" == 0 ]; then
  echo "NAS is up"
  mkdir -p "$DESTINATION_DIR"logs
  echo "==================================" >> $LOGFILE
  ssh kodi_rsync@$NAS_IP -p $SSH_PORT "find $SOURCE_DIR ! -name "*.partial~" -type f -printf '%T@:%p:%s\n'" | egrep -v "@eaDir" | sort -n -r | awk -F":" '{ i+=$3; if (i<=DISK_CAP_BYTES) {print $2}}' > $INPUT_LIST
  rsync -av -e "ssh -p$RSYNC_SSH_PORT" --progress  --human-readable --partial --delete --inplace --exclude '*.partial~' --delete-excluded --log-file=$LOGFILE --files-from=$INPUT_LIST --relative kodi_rsync@$NAS_IP:$USER_BASE_DIR $DESTINATION_DIR 2> $LOGFILE_ERRORS
  echo "==================================" >> $LOGFILE
  find $LOCAL_DIR -type f | sed "s#$DESTINATION_DIR#/#" > $DESTINATION_DIR\logs/local_removefilelist_var01
  awk 'NR==FNR {exclude[$0];next} !($0 in exclude)' $INPUT_LIST $DESTINATION_DIR\logs/local_removefilelist_var01 | sed 's/^.//' | sed "s#^#$DESTINATION_DIR#" | sed 's/.*/"&"/' > $DESTINATION_DIR\logs/local_removefilelist_input
  xargs rm -rf <$DESTINATION_DIR\logs/local_removefilelist_input
  find $LOCAL_DIR depth -type d -delete 2>/dev/null
else
  if [ $NAS_LINK -ne 0 ];then
    echo "############# WARNING #############" >> $LOGFILE_ERRORS
    echo "No network. Aborted: $(date)." >> $LOGFILE_ERRORS
    echo "###################################" >> $LOGFILE_ERRORS
  elif [ $NAS_PING -ne 0 ];then
    echo "############# WARNING #############" >> $LOGFILE_ERRORS
    echo "Cannot ping $NAS_IP. Aborted: $(date)." >> $LOGFILE_ERRORS
    echo "###################################" >> $LOGFILE_ERRORS
  elif [ $MOUNT_CHECK -ne 0 ];then
    echo "############# WARNING #############" >> $LOGFILE_ERRORS
    echo "Remote USB disk is not connected. Aborted: $(date)." >> $LOGFILE_ERRORS
    echo "###################################" >> $LOGFILE_ERRORS
  fi
fi
