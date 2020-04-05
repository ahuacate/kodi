#/bin/sh

# Colour
RED=$'\033[0;31m'
YELLOW=$'\033[1;33m'
GREEN=$'\033[0;32m'
NC=$'\033[0m'

# Messaging
function warn() {
  local REASON="\e[97m$1\e[39m"
  local FLAG="\e[93m[WARNING]\e[39m"
  msg "$FLAG $REASON"
}
function info() {
  local REASON="$1"
  local FLAG="\e[36m[INFO]\e[39m"
  msg "$FLAG $REASON"
}
function msg() {
  local TEXT="$1"
  echo -e "$TEXT"
}

# Cleanup
function cleanup() {
  rm -rf $TEMP_DIR
  cd ~
}

# Set Temp Folder
TEMP_DIR=$(mktemp -d)
cd $TEMP_DIR >/dev/null

# Download external scripts
wget -q https://raw.githubusercontent.com/ahuacate/kodi/master/scripts/coreelec_remote_sharedfolderlist -O coreelec_remote_sharedfolderlist
wget -q https://raw.githubusercontent.com/ahuacate/kodi/master/scripts/coreelec_kodi_rsync_script.sh -O coreelec_kodi_rsync_script.sh

#################################################################################
# This script is for setting up a CoreElec player with a local USB Hard Disk	#
#                                                                 				#
# Tested on : CoreELEC (official): 9.2.1 (Amlogic-ng.arm)						#
#################################################################################

# Command to run script
# bash -c "$(wget -qLO - https://raw.githubusercontent.com/ahuacate/kodi/master/scripts/coreelec_create_remote.sh)"


##################### SETTING USB HARD DISK ##########################


# Select storage location
msg "Detecting USB storage devices..."
STORAGE_LIST="$(ls /dev/disk/by-id/usb* | sed 's/.*usb-\(.*\)-[0-9]:.*/\1/' | awk '!seen[$0]++' | wc -l)" &&
if [ ${STORAGE_LIST} -eq 0 ]; then
  warn "Unable to detect valid USB storage device. \nCheck if USB device is plugged in and re-run this script. \nExiting this installation scipt."
  exit 1
elif [ ${STORAGE_LIST} -eq 1 ]; then
  info "Detected USB storage device: \n${YELLOW}$(ls /dev/disk/by-id/usb* | sed 's/.*usb-\(.*\)-[0-9]:.*/\1/' | awk '!seen[$0]++')${NC}"
  ls /dev/disk/by-id/usb* | sed 's/.*usb-\(.*\)-[0-9]:.*/\1/' | awk '!seen[$0]++' > usb_disk_list
  echo
  msg "Identify the hard disk which you want to use..."
  while true; do
	read -p "Type the first 5 characters of your disk name (above in yellow): " check
	echo
	read -p "Retype the first 5 characters of your disk name (again): " check2
	echo
	[ "$check" = "$check2" ] && break
	echo "Character entries do not match. Please try again."
	done
  cat usb_disk_list | grep -i $check > usb_disk_select
elif [ ${STORAGE_LIST} -gt 1 ]; then
  info "Detected USB storage device: \n${YELLOW}$(ls /dev/disk/by-id/usb* | sed 's/.*usb-\(.*\)-[0-9]:.*/\1/' | awk '!seen[$0]++')${NC}"
  ls /dev/disk/by-id/usb* | sed 's/.*usb-\(.*\)-[0-9]:.*/\1/' | awk '!seen[$0]++' > usb_disk_list
  echo
  msg "Identify the hard disk which you want to use..."
  while true; do
	read -p "Type the first 5 characters of your disk name (above in yellow): " check
	echo
	read -p "Retype the first 5 characters of your disk name (again): " check2
	echo
	[ "$check" = "$check2" ] && break
	echo "Character entries do not match. Please try again."
	done
  cat usb_disk_list | grep -i $check > usb_disk_select
fi
echo


# Format Storage device
msg "Checking the selected disk format (i.e ext3/ext4)..."
MOUNT_POINT="/var/media/remote"
SELECTED_DEVICE="$(readlink -f /dev/disk/by-id/usb-$(cat usb_disk_select)-0:0)"
FORMAT_TYPE="$(blkid -s TYPE $(readlink -f /dev/disk/by-id/usb-$(cat usb_disk_select)-0:0) | awk '{ print $2 }' | awk -F'"' '$0=$2')" &&
if [ "$(echo $FORMAT_TYPE)" == "ext3" ] || [ "$(echo $FORMAT_TYPE)" == "ext4" ]; then
info "Existing disk format is okay: $FORMAT_TYPE"
else
  echo
  info "Your USB storage disk requires formatting to Linux ext4 filesystem"
  while true; do
	read -p "Proceed to format the selected disk to ext4 [type y/n] : " format_run
	echo
	read -p "And reconfirm (again) [type y/n] : " format_run2
	echo
	[ "$format_run" = "$format_run2" ] && break
	echo "Character entries do not match. Please try again."
	done
fi

if [[ $format_run == "y" || $format_run == "Y" || $format_run == "yes" || $format_run == "Yes" ]]; then
msg "Preparing to format the selected disk to ext4 filesystem..."
umount $SELECTED_DEVICE >/dev/null
msg "Erasing the selected disk..."
dd if=/dev/zero of=$SELECTED_DEVICE bs=512 count=1 conv=notrunc >/dev/null
msg "Formating the selected disk..."
yes | mkfs.ext4 -L remote $SELECTED_DEVICE
msg "Running tune2fs to maximise storage capacity..."
tune2fs -m 0 $SELECTED_DEVICE
rm -rf $MOUNT_POINT
mkdir $MOUNT_POINT
msg "Mounting the selected disk at /var/media/remote..."
mount $SELECTED_DEVICE $MOUNT_POINT
echo
info "Success. You have created a ${YELLOW}$(df -h $SELECTED_DEVICE | awk 'FNR == 2 { print $2 }')${NC} storage disk. \nYour new is storage disk is ${YELLOW}remote${NC}."
echo
fi


# Calculate available disk space for media
msg "Calculating the available disk space for media..."
DISK_FACTOR=95
info "Maximum disk storage is set at $DISK_FACTOR% of total disk storage capacity."
DISK_CAP_BYTES=$(SELECTED_DEVICE_MAX=$(df -P $SELECTED_DEVICE | awk 'NR==2 {print $2}') VAR=$DISK_FACTOR busybox sh -c 'echo "$(( SELECTED_DEVICE_MAX * VAR / 100 ))"')
echo


# Create Media Folders
msg "Creating default media folders..."
if mountpoint $MOUNT_POINT >/dev/null; then
schemaExtractDir="$MOUNT_POINT"
while read dir; do
dir="$schemaExtractDir/$dir"
if [ -d "$dir" ]; then
info "$dir exists, not creating this folder."
echo
else
info "$dir does not exist: creating one for you..."
mkdir -p "${dir}"
echo
fi
done < coreelec_remote_sharedfolderlist # file listing of folders to create
fi
echo


echo "##################### SETTING UP RSYNC SCRIPT ##########################"
echo


# Create Script folders and set permissions
msg "Creating default script storage folder..."
mkdir -p /storage/.config/scripts
chmod 775 /storage/.config/scripts
ln -s /storage/.config/scripts /storage/scripts
echo


# Copy coreelec_kodi_rsync_script.sh to script folder
msg "Copying coreelec_kodi_rsync_script.sh to /storage/.config/scripts..."
cp coreelec_kodi_rsync_script.sh /storage/.config/scripts
chmod 755 /storage/.config/scripts/coreelec_kodi_rsync_script.sh
echo


# Identifying your NAS IPv4 address
msg "Identify your NAS IPv4 address..."
while true; do
  read -p "Type the IPv4 address of your NAS (i.e 192.168.1.10): " NAS_IP
  echo
  read -p "Confirmation. Retype IPv4 address of your NAS (again): " NAS_IP_CHECK
  echo "Validating your NAS IPv4 address..."
  [ "$NAS_IP" = "$NAS_IP_CHECK" ] && [ $(ping -s 1 -c 2 "$NAS_IP" > /dev/null; echo $?) == 0 ] && break
  if [ "$NAS_IP" != "$NAS_IP_CHECK" ]; then
echo "${RED}$NAS_IP${NC} and ${RED}$NAS_IP_CHECK${NC} DO NOT MATCH.
Please try again."
  elif [ $(ping -s 1 -c 2 "$NAS_IP" > /dev/null; echo $?) == 1 ]; then
echo "NAS IPv4 address ${RED}$NAS_IP${NC} is not reachable.
Check NAS is on the network and ${RED}$NAS_IP${NC} address is correct.
Please try again."
  fi
done
echo


# Checking NAS Hardware Type
msg "Checking NAS hardware type (i.e Synology, Ubuntu Server)..."
ssh kodi_rsync@$NAS_IP "uname -a" 2>/dev/null > nas_uname.txt
if [ $(egrep -i "synology|diskstation" -q nas_uname.txt 2>/dev/null; echo $?) == 0 ]; then
  info "Identified a ${YELLOW}Synology Diskstation${NC}."
  NAS_TYPE="Synology"
  USER_BASE_DIR="~"
  SOURCE_BASE_DIR="$(ssh kodi_rsync@$NAS_IP "find / -type d -name "homes" 2>/dev/null" | egrep -v "@" | sed 's/\/homes*//')"
elif [ $(egrep -i "ubuntu" -q nas_uname.txt 2>/dev/null; echo $?) == 0 ]; then
  info "Identified a ${YELLOW}Ubuntu File Server${NC}."
  NAS_TYPE="Ubuntu"
  warn "Coming Soon. Sorry." # To Be Completed
  exit
fi
echo


# Confirming Folders to Rsync
msg "Please select which media folders to Rsync..."
read -p "Do you want to synchronise your $NAS_TYPE TV Shows folder [yes/no]? " -r
if [[ "$REPLY" == "y" || "$REPLY" == "Y" || "$REPLY" == "yes" || "$REPLY" == "Yes" ]]; then
while true
  read -p "Type the $NAS_TYPE folder name which contains all your TV shows (i.e TV or TVShows): " TV_DIR_CHECK
  do
  echo "Validating this folder exists: ${YELLOW}$TV_DIR_CHECK${NC} ..."
  if [ $(ssh kodi_rsync@$NAS_IP "find / -type d -iname "$TV_DIR_CHECK" 2>/dev/null" | egrep -v "@" > /dev/null; echo $?) == 0 ]; then
    TV_DIR_CHECK2=$(ssh kodi_rsync@$NAS_IP "find / -type d -iname "$TV_DIR_CHECK" 2>/dev/null" | egrep -v "@")
	echo "$TV_DIR_CHECK" >> media_sources_search
    read -p "Confirm the following path is correct for your TV Shows folder: ${YELLOW}$TV_DIR_CHECK2${NC} [yes/no]?: " -r
	if [[ "$REPLY" == "y" || "$REPLY" == "Y" || "$REPLY" == "yes" || "$REPLY" == "Yes" ]]; then
      TV_DIR=$(ssh kodi_rsync@$NAS_IP "find / -type d -iname "$TV_DIR_CHECK" 2>/dev/null" | egrep -v "@")
	  echo "$TV_DIR" >> media_sources_input
      info "TV Show folder is set as: ${YELLOW}$TV_DIR${NC}"
	  TV_DIR_SYNC=0 # Setting variable so not to list any like folders
	  break
	elif [[ "$REPLY" == "n" || "$REPLY" == "N" || "$REPLY" == "no" || "$REPLY" == "No" ]]; then
	  warn "If we cannot find it, we cannot add it! Sorry. Moving on."
	  break
	fi
  else
    warn "Folder $TV_DIR_CHECK does not exits OR is not reachable by user kodi_rsync.
Please check your $NAS_TYPE TV Show folder name and kodi_rsync user permissions.
Trying again."
    echo
  fi
done
else
TV_DIR_SYNC=1 # Setting variable so not to list any like folders
info "You have chosen NOT to synchronise any TV Shows. Skipping this step."
fi
echo

info "Setting up your Movies folder."
read -p "Do you want to synchronise your $NAS_TYPE Movies folder [yes/no]? " -r
if [[ "$REPLY" == "y" || "$REPLY" == "Y" || "$REPLY" == "yes" || "$REPLY" == "Yes" ]]; then
while true
  read -p "Type the $NAS_TYPE folder name which contains all your Movies (i.e Movies or Movie): " MOVIE_DIR_CHECK
  do
  echo "Validating this folder exists: ${YELLOW}$MOVIE_DIR_CHECK${NC} ..."
  if [ $(ssh kodi_rsync@$NAS_IP "find / -type d -iname "$MOVIE_DIR_CHECK" 2>/dev/null" | egrep -v "@" > /dev/null; echo $?) == 0 ]; then
    MOVIE_DIR_CHECK2=$(ssh kodi_rsync@$NAS_IP "find / -type d -iname "$MOVIE_DIR_CHECK" 2>/dev/null" | egrep -v "@")
	echo "$MOVIE_DIR_CHECK" >> media_sources_search
    read -p "Confirm the following path is correct for your Movies folder: ${YELLOW}$MOVIE_DIR_CHECK2${NC} [yes/no]?: " -r
	if [[ "$REPLY" == "y" || "$REPLY" == "Y" || "$REPLY" == "yes" || "$REPLY" == "Yes" ]]; then
      MOVIE_DIR=$(ssh kodi_rsync@$NAS_IP "find / -type d -iname "$MOVIE_DIR_CHECK" 2>/dev/null" | egrep -v "@")
	  echo "$MOVIE_DIR" >> media_sources_input
      info "Movies folder is set as: ${YELLOW}$MOVIE_DIR${NC}"
	  MOVIE_DIR_SYNC=0 # Setting variable so not to list any like folders
	  break
	elif [[ "$REPLY" == "n" || "$REPLY" == "N" || "$REPLY" == "no" || "$REPLY" == "No" ]]; then
	  warn "If we cannot find it, we cannot add it! Sorry. Moving on."
	  break
	fi
  else
    warn "Folder $MOVIE_DIR_CHECK does not exits OR is not reachable by user kodi_rsync.
Please check your $NAS_TYPE Movies folder name and kodi_rsync user permissions.
Trying again."
    echo
  fi
done
else
MOVIE_DIR_SYNC=1 # Setting variable so not to list any like folders
info "You have chosen NOT to synchronise any Movies. Skipping this step."
fi
echo

info "Setting up your Music folder."
read -p "Do you want to synchronise your $NAS_TYPE Music folder [yes/no]? " -r
if [[ "$REPLY" == "y" || "$REPLY" == "Y" || "$REPLY" == "yes" || "$REPLY" == "Yes" ]]; then
while true
  read -p "Type the $NAS_TYPE folder name which contains all your Music (i.e Music): " MUSIC_DIR_CHECK
  do
  echo "Validating this folder exists: ${YELLOW}$MUSIC_DIR_CHECK${NC} ..."
  if [ $(ssh kodi_rsync@$NAS_IP "find / -type d -iname "$MUSIC_DIR_CHECK" 2>/dev/null" | egrep -v "@" > /dev/null; echo $?) == 0 ]; then
    MUSIC_DIR_CHECK2=$(ssh kodi_rsync@$NAS_IP "find / -type d -iname "$MUSIC_DIR_CHECK" 2>/dev/null" | egrep -v "@")
	echo "$MUSIC_DIR_CHECK" >> media_sources_search
    read -p "Confirm the following path is correct for your Music folder: ${YELLOW}$MUSIC_DIR_CHECK2${NC} [yes/no]?: " -r
	if [[ "$REPLY" == "y" || "$REPLY" == "Y" || "$REPLY" == "yes" || "$REPLY" == "Yes" ]]; then
      MUSIC_DIR=$(ssh kodi_rsync@$NAS_IP "find / -type d -iname "$MUSIC_DIR_CHECK" 2>/dev/null" | egrep -v "@")
	  echo "$MUSIC_DIR" >> media_sources_input
      info "Music folder is set as: ${YELLOW}$MUSIC_DIR${NC}"
	  MUSIC_DIR_SYNC=0 # Setting variable so not to list any like folders
	  break
	elif [[ "$REPLY" == "n" || "$REPLY" == "N" || "$REPLY" == "no" || "$REPLY" == "No" ]]; then
	  warn "If we cannot find it, we cannot add it! Sorry. Moving on."
	  break
	fi
  else
    warn "Folder $MUSIC_DIR_CHECK does not exits OR is not reachable by user kodi_rsync.
Please check your $NAS_TYPE Music folder name and kodi_rsync user permissions.
Trying again."
    echo
  fi
done
else
MUSIC_DIR_SYNC=1 # Setting variable so not to list any like folders
info "You have chosen NOT to synchronise any Music. Skipping this step."
fi
echo

info "Setting up your Photo folder."
read -p "Do you want to synchronise your $NAS_TYPE Photo folder [yes/no]? " -r
if [[ "$REPLY" == "y" || "$REPLY" == "Y" || "$REPLY" == "yes" || "$REPLY" == "Yes" ]]; then
while true
  read -p "Type the $NAS_TYPE folder name which contains all your Photos (i.e Photo or Photos): " PHOTO_DIR_CHECK
  do
  echo "Validating this folder exists: ${YELLOW}$PHOTO_DIR_CHECK${NC} ..."
  if [ $(ssh kodi_rsync@$NAS_IP "find / -type d -iname "$PHOTO_DIR_CHECK" 2>/dev/null" | egrep -v "@" > /dev/null; echo $?) == 0 ]; then
    PHOTO_DIR_CHECK2=$(ssh kodi_rsync@$NAS_IP "find / -type d -iname "$PHOTO_DIR_CHECK" 2>/dev/null" | egrep -v "@")
	echo "$PHOTO_DIR_CHECK" >> media_sources_search
    read -p "Confirm the following path is correct for your Photo folder: ${YELLOW}$PHOTO_DIR_CHECK2${NC} [yes/no]?: " -r
	if [[ "$REPLY" == "y" || "$REPLY" == "Y" || "$REPLY" == "yes" || "$REPLY" == "Yes" ]]; then
      PHOTO_DIR=$(ssh kodi_rsync@$NAS_IP "find / -type d -iname "$PHOTO_DIR_CHECK" 2>/dev/null" | egrep -v "@")
	  echo "$PHOTO_DIR" >> media_sources_input
      info "Photo folder is set as: ${YELLOW}$PHOTO_DIR${NC}"
	  PHOTO_DIR_SYNC=0 # Setting variable so not to list any like folders
	  break
	elif [[ "$REPLY" == "n" || "$REPLY" == "N" || "$REPLY" == "no" || "$REPLY" == "No" ]]; then
	  warn "If we cannot find it, we cannot add it! Sorry. Moving on."
	  break
	fi
  else
    warn "Folder $PHOTO_DIR_CHECK does not exits OR is not reachable by user kodi_rsync.
Please check your $NAS_TYPE Photo folder name and kodi_rsync user permissions.
Trying again."
    echo
  fi
done
else
PHOTO_DIR_SYNC=1 # Setting variable so not to list any like folders
info "You have chosen NOT to synchronise any Photos. Skipping this step."
fi
echo


# Select other folders under Video folder
msg "Identify if any other media folders exist..."
awk '!seen[$0]++' media_sources_input > media_sources_output # Cleanup duplicates in file input_media_sources
# Seek out containing folder name for tv and movies
if [[ "$(cat media_sources_output | egrep -i "(tv|tvshow|tv show)" | sed 's,/*[^/]\+/*$,,')" == "$(cat media_sources_output | egrep -i "(movie|cinema)" | sed 's,/*[^/]\+/*$,,')" ]]; then
  ssh kodi_rsync@$NAS_IP "ls -d $(cat media_sources_output | egrep -i "(tv|tvshow|tv show)" | sed 's,/*[^/]\+/*$,,')/* | egrep -i -v "@"" | egrep -i -v -f media_sources_output > media_sources_extra
fi 2>/dev/null

if [ -f "media_sources_extra" ] && [ "$(cat media_sources_extra | sed -n '$=' $1 2>/dev/null)" -gt "0" ]; then
  while read line <&3
  do
  echo "Identified an additional media folder: ${YELLOW}$line${NC}"
  read -p "Do you want to synchronise path: ${YELLOW}$line${NC} [yes/no]? " -r
  if [[ "$REPLY" == "y" || "$REPLY" == "Y" || "$REPLY" == "yes" || "$REPLY" == "Yes" ]]; then 
    info "Adding path $line for synchronisation."
	echo "$line" >> media_sources_input
    echo
  else
    info "Ignoring path $line. Not being synchronised."
    echo
  fi
  done 3< "media_sources_extra"
info "No more extra folders found. Task completed."
fi
echo


# Set Scheduled Cron Tasks
msg "Setting crontab to run the Rsync at 01:00hr daily..."
crontab -l > kodi_rsync # write out crontab
echo "0 1 * * * sh /storage/.config/scripts/coreelec_kodi_rsync_script.sh" >> kodi_rsync # echo new cron into cron file
crontab kodi_rsync # install new cron file
rm kodi_rsync # delete temp echo file
info "Rsync set to run everyday at 01:00hr."
echo


# Setting Variables in Script
msg "Setting script variables..."
sed -i 's/NAS_TYPE=.*/NAS_TYPE="'$NAS_TYPE'"/g' /storage/.config/scripts/coreelec_kodi_rsync_script.sh
sed -i 's/NAS_IP=.*/NAS_IP="'$NAS_IP'"/g' /storage/.config/scripts/coreelec_kodi_rsync_script.sh
sed -i 's/DISK_CAP=.*/DISK_CAP="'$DISK_CAP_BYTES'"/g' /storage/.config/scripts/coreelec_kodi_rsync_script.sh
sed -i 's/USER_BASE_DIR=.*/USER_BASE_DIR="'$USER_BASE_DIR'"/g' /storage/.config/scripts/coreelec_kodi_rsync_script.sh
sed -i 's/SOURCE_BASE_DIR=.*/SOURCE_BASE_DIR="'$SOURCE_BASE_DIR'"/g' /storage/.config/scripts/coreelec_kodi_rsync_script.sh
sed -i 's/SOURCE_DIR=.*/SOURCE_DIR="'cat media_sources_input | tr '\n' ' ''"/g' /storage/.config/scripts/coreelec_kodi_rsync_script.sh
info "Rsync script variables set."
echo


# Setting up New Kodi Profile Names
read -p "Do you want to create a new Kodi user profile to use the new hard disk [yes/no]? " -r
if [[ "$REPLY" == "y" || "$REPLY" == "Y" || "$REPLY" == "yes" || "$REPLY" == "Yes" ]]; then
info "You have chosen to create a new Kodi user profile."
# Create Remote_user Profile Name
msg "Creating new Kodi user profile called Remote_user..."
info "Stopping Kodi."
systemctl stop kodi
sleep 2
info "Cleaning up the Kodi Temp folder."
find /storage/.kodi/temp/. -type f -size 0b -delete
info "Setting up new profile for user Remote_user."
sed -i 's|<useloginscreen>.*</useloginscreen>|<useloginscreen>true</useloginscreen>|g' ~/.kodi/userdata/profiles.xml
mkdir -p ~/.kodi/userdata/profiles/remote_user
count=$(sed -n 's:.*<nextIdProfile>\(.*\)</nextIdProfile>.*:\1:p' ~/.kodi/userdata/profiles.xml)
sed -i '$ d' ~/.kodi/userdata/profiles.xml
cat <<EOF >> ~/.kodi/userdata/profiles.xml
    <profile>
        <id>$count</id>
        <name>Remote_user</name>
        <directory pathversion="1">profiles/remote_user/</directory>
        <thumbnail pathversion="1"></thumbnail>
        <hasdatabases>true</hasdatabases>
        <canwritedatabases>true</canwritedatabases>
        <hassources>true</hassources>
        <canwritesources>true</canwritesources>
        <lockaddonmanager>false</lockaddonmanager>
        <locksettings>0</locksettings>
        <lockfiles>false</lockfiles>
        <lockmusic>false</lockmusic>
        <lockvideo>false</lockvideo>
        <lockpictures>false</lockpictures>
        <lockprograms>false</lockprograms>
        <lockgames>false</lockgames>
        <lockmode>0</lockmode>
        <lockcode>-</lockcode>
        <lastdate>28/03/2020 - 4:00 PM</lastdate>
    </profile>
</profiles>
EOF
info "Restarting Kodi - waiting 5 seconds"
systemctl start kodi
sleep 5
echo


# Editing Remote_user GUI settings
msg "Setting Remote_user default resolution settings to standard 1080p."
systemctl stop kodi
sleep 2
sed -i 's|<setting id="locale.audiolanguage">.*</setting>|<setting id="locale.audiolanguage">English</setting>|g' ~/.kodi/userdata/profiles/remote_user/guisettings.xml
sed -i 's|<setting id="locale.charset".*</setting>|<setting id="locale.charset" default="true">DEFAULT</setting>|g' ~/.kodi/userdata/profiles/remote_user/guisettings.xml
sed -i 's|<setting id="locale.country".*</setting>|<setting id="locale.country">Australia (12h)</setting>|g' ~/.kodi/userdata/profiles/remote_user/guisettings.xml
sed -i 's|<setting id="locale.language".*</setting>|<setting id="locale.language" default="true">resource.language.en_gb</setting>|g' ~/.kodi/userdata/profiles/remote_user/guisettings.xml
sed -i 's|<setting id="locale.longdateformat".*</setting>|<setting id="locale.longdateformat" default="true">regional</setting>|g' ~/.kodi/userdata/profiles/remote_user/guisettings.xml
sed -i 's|<setting id="locale.shortdateformat".*</setting>|<setting id="locale.shortdateformat" default="true">regional</setting>|g' ~/.kodi/userdata/profiles/remote_user/guisettings.xml
sed -i 's|<setting id="locale.speedunit".*</setting>|<setting id="locale.speedunit" default="true">regional</setting>|g' ~/.kodi/userdata/profiles/remote_user/guisettings.xml
sed -i 's|<setting id="locale.subtitlelanguage".*</setting>|<setting id="locale.subtitlelanguage">English</setting>|g' ~/.kodi/userdata/profiles/remote_user/guisettings.xml
sed -i 's|<setting id="locale.temperatureunit".*</setting>|<setting id="locale.temperatureunit" default="true">regional</setting>|g' ~/.kodi/userdata/profiles/remote_user/guisettings.xml
sed -i 's|<setting id="locale.timeformat".*</setting>|<setting id="locale.timeformat" default="true">regional</setting>|g' ~/.kodi/userdata/profiles/remote_user/guisettings.xml
sed -i 's|<setting id="locale.timezone".*</setting>|<setting id="locale.timezone">Australia/Melbourne</setting>|g' ~/.kodi/userdata/profiles/remote_user/guisettings.xml
sed -i 's|<setting id="locale.timezonecountry".*</setting>|<setting id="locale.timezonecountry">Australia</setting>|g' ~/.kodi/userdata/profiles/remote_user/guisettings.xml
sed -i 's|<setting id="locale.use24hourclock".*</setting>|<setting id="locale.use24hourclock" default="true">regional</setting>|g' ~/.kodi/userdata/profiles/remote_user/guisettings.xml
sed -i 's|<setting id="subtitles.languages".*</setting>|<setting id="subtitles.languages" default="true">English</setting>|g' ~/.kodi/userdata/profiles/remote_user/guisettings.xml
sed -i 's|<setting id="subtitles.movie".*</setting>|<setting id="subtitles.movie" default="true"></setting>|g' ~/.kodi/userdata/profiles/remote_user/guisettings.xml
sed -i 's|<setting id="subtitles.tv".*</setting>|<setting id="subtitles.tv" default="true"></setting>|g' ~/.kodi/userdata/profiles/remote_user/guisettings.xml
sed -i 's|<setting id="videoscreen.resolution".*</setting>|<setting id="videoscreen.resolution">24</setting>|g' ~/.kodi/userdata/profiles/remote_user/guisettings.xml
sed -i 's|<setting id="videoscreen.screenmode".*</setting>|<setting id="videoscreen.screenmode">0192001080059.94006pstd</setting>|g' ~/.kodi/userdata/profiles/remote_user/guisettings.xml
systemctl start kodi
sleep 2
echo
else
info "You have chosen to manually create a local profile at your Kodi player station."
fi


# Manually Run Rsync Script
msg "Option to run Rsync manually (now)..."



# Success
msg "${GREEN}Success!!!!!${NC} Cleaning up temporary files..."
cleanup
