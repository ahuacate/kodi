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

## 1.00 Setup and perform CoreElec base configuration
Coming soon. 

### 1.01 CoreElec base settings
Coming Soon.

## 2.00 CoreElec Common Settings
Use the Kodi TV GUI and go to the Settings Dashboard.

## 3.00 Kodi Settings

## 4.00 Install Jellyfin Addon

## 5.00 Install VNC Addon

## 6.00 Make your CoreElec Player portable - No Internet Access
This recipe is for those who want to take their CoreElec player offsite to a remote location which has no internet access or LAN network. This works by attaching a USB3 hard disk to the CoreElec player and running RSYNC to synchronise your NAS media library locally.

The prerequisites are:
- [x] External USB3 2,5" Disk Drive
- [x] A working build of CoreElec/LibreElec with network access

### 6.01 Prepare your NAS - Type Synology
**Enable User Homes**

Open `Control Panel` > `User` > `Advanced` > `User Home`

| User Home | Value | Note |
| :---  | :---: | :--- |
| Enable User home service | `☑`
| Enable Recycle Bin | `☐`

**Create a New User**

1. Open `Control Panel` > `User` > `Create`
2. Set User Information as follows:
   * Name: `kodi_sync`
   * Description: `Medialab - Kodi to NAS SSH Sync User`
   * Email: `Leave blank`
   * Password: `As Supplied`
   * Confirm password: `As Supplied`
     * Send notification mail to the newly created user: ☐ 
     * Display user password in notification mail: ☐ 
     * Disallow the user to change account password:  `☑`
3. Set Join groups as follows:
     * medialab:  `☑`
     * users:  `☑`
4. Assign shared folders permissions as follows:
     * Leave as default because all permissions are automatically obtained from the medialab user 'group' permissions.
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

**Enable Public Key Authentication**

Public Key Authentication is now enabled by default in the latest Synology OS version even if the settings are commented out in sshd_config. So you should be able to skip this and jump to `Generate an SSH Key`. But here are the instructions anyway.

Log in to your NAS using ssh:

```
ssh -p <port> your-nas-user@your-nas-hostname
```

Open the SSH server configuration file for editing:

sudo vim /etc/ssh/sshd_config

Find the following lines and uncomment them (remove the #):

#RSAAuthentication yes
#PubkeyAuthentication yes

It's possible to restart the service using the following command:

sudo synoservicectl --reload sshd


### 6.02 Prepare your NAS - Type Proxmox Ubuntu Fileserver




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
