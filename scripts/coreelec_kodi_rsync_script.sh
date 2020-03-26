#!/bin/sh

#####################VARIABLES DEFINED##########################

NAS_IP="192.168.1.11"

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
#wget -q https://raw.githubusercontent.com/ahuacate/kodi/master/scripts/coreelec_kodi_rsync_script.sh

if [ "$NAS_LINK" == 0 ] && [ "$NAS_PING" == 0 ] && [ "$MOUNT_CHECK" == 0 ]; then
  echo "NAS is up"
  mkdir -p /var/media/remote/logs
  echo "==================================" >> $LOGFILE
  rsync -avuz --delete --exclude '*.partial~' --delete-excluded --log-file=$LOGFILE kodi_rsync@$NAS_IP:/volume1/rsync/ /var/media/remote/music 2> $LOGFILE_ERRORS
  echo "==================================" >> $LOGFILE
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
    echo "Remote disk is not connected. Aborted: $(date)." >> $LOGFILE_ERRORS
    echo "###################################" >> $LOGFILE_ERRORS
  fi
fi