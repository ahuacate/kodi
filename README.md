# Kodi Build
This recipe is for setting up Kodi built on CoreElec (probably works fine on Libreelec).

Network Prerequisites are:
- [x] Layer 2 Network Switches
- [x] Network Gateway is `192.168.1.5`
- [x] Network DNS server is `192.168.1.5` (Note: your Gateway hardware should enable you to a configure DNS server(s), like a UniFi USG Gateway, so set the following: primary DNS `192.168.1.254` which will be your PiHole server IP address; and, secondary DNS `1.1.1.1` which is a backup Cloudfare DNS server in the event your PiHole server 192.168.1.254 fails or os down)
- [x] Network DHCP server is `192.168.1.5`

Other Prerequisites are:
- [x] Synology NAS, or linux variant of a NAS, is fully configured as per [SYNOBUILD](https://github.com/ahuacate/synobuild#synobuild).
- [x] Proxmox node fully configured as per [PROXMOX-NODE BUILDING](https://github.com/ahuacate/proxmox-node/blob/master/README.md#proxmox-node-building).
- [x] Jellyfin LXC with Jellyfin SW installed as per [Jellyfin LXC - Ubuntu 18.04](https://github.com/ahuacate/proxmox-lxc/blob/master/README.md#30-jellyfin-lxc---ubuntu-1804).

Tasks to be performed are:
- [1.00 Setup and perform CoreElec base configuration](#100-setup-and-perform-coreelec-base-configuration)
	- [1.01 CoreElec base settings](#101-coreelec-base-settings)
- [2.00 CoreElec Common Settings](#200-coreelec-common-settings)
- [3.00 Kodi Settings](#300-kodi-settings)
- [4.00 Install Jellyfin Addon](#400-install-jellyfin-addon)
- [5.00 Install VNC Addon](#500-install-vnc-addon)
- [6.00 Build a portable CoreElec Player - No Internet or LAN Access](#600-build-a-portable-coreelec-player---no-internet-or-lan-access)
	- [6.01 Prepare your NAS - Type Synology](#601-prepare-your-nas---type-synology)
	- [6.02 Prepare your NAS - Type Proxmox Ubuntu Fileserver](#602-prepare-your-nas---type-proxmox-ubuntu-fileserver)
	- [6.03 Prepare CoreElec for SSH Rsync to NAS](#603-prepare-coreelec-for-ssh-rsync-to-nas)
	- [6.04 Setup Rsync on CoreElec](#604-setup-rsync-on-coreelec)
- [00.00 Patches & Fixes](#0000-patches--fixes)
	- [00.01 Patch for Odroid N2 CoreElec connected to LG C9 OLED - CoreELEC](#0001-patch-for-odroid-n2-coreelec-connected-to-lg-c9-oled---coreelec)
	- [00.02 LG Patch for CoreELEC keymapping to LG C9 magic remote control - CoreELEC](#0002-lg-patch-for-coreelec-keymapping-to-lg-c9-magic-remote-control---coreelec)

---

## 1.00 Setup and perform CoreElec base configuration
Coming soon. 

### 1.01 CoreElec base settings
Coming Soon.

## 2.00 CoreElec Common Settings
Use the Kodi TV GUI and go to the Settings Dashboard.

## 3.00 Kodi Settings

## 4.00 Install Jellyfin Addon

## 5.00 Install VNC Addon

## 6.00 Build a portable CoreElec Player - No Internet or LAN Access
Make a portable CoreElec player to use in remote locations. Like homes with no internet or LAN network.

This is achieved by attaching a USB3 hard disk to your CoreElec hardware and running CoreElec native RSYNC to synchronise your NAS media library to the attached USB3 hard disk.

The prerequisites are:
- [x] External USB3 2,5" Disk Drive
- [x] A working build of CoreElec/LibreElec with network access
- [x] A running NAS with Rsync

### 6.01 Prepare your NAS - Type Synology
**Install NANO from Synology Package Centre**

When you only need Nano, you can install it as a SynoCommunity package. First open `Package Center` > `Settings` > `Package Sources` > `Add` :

| Add | Value | Notes |
| :---  | :---: | :--- |
| Name | `SynoCommunity`
| Location | `http://packages.synocommunity.com/` | 

Click `OK`. 

Now type in the search bar `nano` and install the nano package.
   
**Enable User Homes**

Open `Control Panel` > `User` > `Advanced` > `User Home` and complete as follows:

| User Home | Value | Note |
| :---  | :---: | :--- |
| Enable User home service | `☑`
| Enable Recycle Bin | `☑` | *Disable if you prefer.*

**Create a New User**

1. Open `Control Panel` > `User` > `Create`
2. Set User Information as follows:
   * Name: `kodi_rsync`
   * Description: `Medialab - Kodi to NAS SSH Rsync User`
   * Email: `Leave blank`
   * Password: `As Supplied`
   * Confirm password: `As Supplied`
     * Send notification mail to the newly created user: ☐ 
     * Display user password in notification mail: ☐ 
     * Disallow the user to change account password:  `☑`
3. Set Join groups as follows:

| User Groups | Add | Notes |
| :---  | :---: | :--- |
| administrators | `☑` | *Required for testing SSH connection. After testing, toggle off for rsync only.*
| medialab | `☑` |
| users | `☑` | *ONLY Enable if you have no medialab group*

4. Assign shared folders permissions as follows:
     * Leave as default because all permissions are automatically obtained from the medialab user 'group' permissions. But you should at least have `rsync` and 'homes' set to `read/write`.
     
| Assigned shared folder Permissions | Preview | Group permissions | No access | Read/Write | Read only
| :---  | :---: | :---: | :---: | :---: | :---: |
| homes | Read/Write | - | ☐ | `☑` | ☐ 
| rsync | Read/Write | - | ☐ | `☑` | ☐ 

5. Set User quota setting:
     * `default`
6. Assign application permissions:
     * Leave as default because all application permissions are automatically obtained from the medialab user 'group' permissions.
7. Set User Speed Limit Setting:
     * `default`
8. Confirm settings:
     * `Apply`

**Enable SSH Server**

Log in to the Synology Desktop and go to `Control Panel` > `Terminal & SNMP`.

Check `Enable SSH Service` and choose a non-default port. If you use the default port of 22 you'll get a security warning later.

| Terminal | Value | Note |
| :---  | :---: | :--- |
| Enable Telnet service | `☐`
| Enable SSH service | `☑`
| Port | 22 | *Change if you want to increase security. Note new port number.*

**Enable Public Key Authentication**

Public Key Authentication is now enabled by default in the latest Synology OS version even if the settings are commented out in sshd_config. So you should be able to skip this and jump to `Generate an SSH Key`. But here are the instructions anyway.

1. Log in to your NAS using SSH with user `kodi_rsync`:

```
ssh kodi_rsync@your-nas-IP
```
Or if you change your SSH port (no longer default port 22) type:
```
ssh -p <port> kodi_rsync@your-nas-IP
```

2. Run the following commands (copy & paste) in your terminal window. You will be prompted for a password so enter user `kodi_rsync` password:

```
echo "Editing SSH server configuration file..." &&
sudo sed -i 's|#RSAAuthentication yes|RSAAuthentication yes|g' /etc/ssh/sshd_config &&
sudo sed -i 's|#PubkeyAuthentication yes|PubkeyAuthentication yes|g' /etc/ssh/sshd_config &&
sudo sed -i 's|#AuthorizedKeysFile     .ssh/authorized_keys|AuthorizedKeysFile     .ssh/authorized_keys|g' /etc/ssh/sshd_config &&
echo "Creating authorised keys folders for user kodi_rsync..." &&
mkdir /var/services/homes/kodi_rsync/.ssh &&
chmod 700 /var/services/homes/kodi_rsync/.ssh &&
touch /var/services/homes/kodi_rsync/.ssh/authorized_keys &&
chmod 600 /var/services/homes/kodi_rsync/.ssh/authorized_keys &&
chmod 700 /var/services/homes/kodi_rsync &&
ln -s /volume1 /var/services/homes/kodi_rsync/volume1 &&
echo "Restarting SSH service..." &&
sudo synoservicectl --reload sshd &&
echo "Success. Finished script." &&
echo
```

### 6.02 Prepare your NAS - Type Proxmox Ubuntu Fileserver
Coming Soon.

### 6.03 Prepare CoreElec for SSH Rsync to NAS
Here we generate a SSH RSA key and copy the public key (id_rsa.pub) to your NAS.

1. Log in to your CoreElec player using SSH. Default user is `root` and password is `coreelec` (for libreelec the default password is `libreelec`):

```
ssh root@your-coreelec-IP
```

2. Run the following commands (copy & paste) in corelec. You will need to enter your NAS user 'kodi_rsync` password to complete the task.

```
read -p "Please enter your NAS IPv4 address (ie 192.168.1.10) : " NAS_IP &&
rm -rf ~/.ssh/id* &&
echo "Generating RSA authentication keys..." &&
ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa >/dev/null &&
echo "Get ready to enter your NAS user kodi_rsync password at the prompt..." &&
cat ~/.ssh/id_rsa.pub | ssh kodi_rsync@$NAS_IP 'cat > /var/services/homes/kodi_rsync/.ssh/authorized_keys' &&
echo &&
echo "Now testing your SSH RSA key connection..." &&
ssh -q kodi_rsync@NAS_IP exit &&
if [ "$(echo $?)" = 0 ]; then
echo
echo "Success. RSA key authentication is working."
fi
```

### 6.04 Setup Rsync on CoreElec
The prerequisites are:

- [x] External USB3 2,5" Disk Drive plugged in and powered;
- [x] A working build of CoreElec/LibreElec with internet & LAN network access;
- [x] A running NAS with Rsync;

And have available or noted for the installation script:

- [x] NAS folder names which you want to synchronise (i.e movies, tv or tvshows, music, photos etc). They must be exact.

Next simply run our installation script. The script will prompt you for user input.

1. Log in to your CoreElec player using SSH. Default user is `root` and password is `coreelec` (for libreelec the default password is `libreelec`):

```
ssh root@your-coreelec-IP
```

2. Run the following commands (copy & paste) in the SSH terminal. You will be prompted for user inputs to complete the script tasks.

```
wget -q https://raw.githubusercontent.com/ahuacate/kodi/master/scripts/coreelec_create_remote.sh -O coreelec_create_remote.sh; chmod +x coreelec_create_remote.sh; ./coreelec_create_remote.sh
```

#  00.00 Patches & Fixes
Tweaks and fixes to make broken things work - sometimes.

## 00.01 Patch for Odroid N2 CoreElec connected to LG C9 OLED - CoreELEC
When setting the CoreELEC `Settings` > `System` > `Display` > `Resolution` to 3840x2160p your screen may flicker and tear.

The solution is to SSH into your CoreELEC device (default credentials: username > `root` | password > `coreelec`) and perform the following steps:

**Step 1**
```
systemctl stop kodi
```

**Step 2**
Delete all resolution related sections ( i.e everything between `<resolutions>` and `<resolutions>`) from guisettings.xml
```
nano ~/.kodi/userdata/guisettings.xml
```
Use "Ctrl K" to delete the selected lines, "CTRL O" to save the file and "CTRL X" to exit.

**Step 3**
```
systemctl start kodi
```

## 00.02 LG Patch for CoreELEC keymapping to LG C9 magic remote control - CoreELEC
Want to fix your LG magic remote - add those missing keys!

My keymaps fixes are as follows:

![alt text](https://raw.githubusercontent.com/ahuacate/kodi/master/images/LG_c9_remote.png)

SSH into your CoreELEC device (default credentials: username > `root` | password > `coreelec`) and run the following command to create keymapping:
```
cat << EOF > ~/.kodi/userdata/keymaps/remote.xml
<keymap>
    <global>
        <remote>
            <red>stop</red>
            <blue>ContextMenu</blue>
            <yellow>CodecInfo</yellow>
        </remote>
    </global>
</keymap> 
EOF
```
And reboot your device for the keymapping to take effect.
