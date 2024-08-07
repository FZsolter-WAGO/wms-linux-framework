# The new installer is available at https://wms-installer.wago.ms/overview.html . This installer will be deprecated soon.


# WAGO Monitoring Solution Linux framework installer

## WARNING! Debian is not supported currently, therefore WAGO stock firmware neither!
### This is because of an unfortunate PHP error while using >8.1.26 versions. Since a new release is planned that will be using PHP8.2 the issue will not be fixed. 

## Only Ubuntu 22.04 is supported!

Anything can have a mascot

![snek](snek.png)

### Usage

0) Login as root via SSH
1) Configure network settings to access the Internet
2) Remove any Docker installation (the docker0 network interface is constantly changing its MAC address, so the license key will change every time the server is restarted)

   Reboot when the uninstallation is complete
   ```
   apt purge docker* -y && apt autoremove -y && reboot
   ```
3) Update the system, and install curl
   ```
   apt update && apt full-upgrade -y && apt install curl -y
   ```
4) Upload the desired "wms_x.x.x.tar.gz" package

   It is recommended to upload the package to /root/wms_x.x.x.tar.gz using SFTP (with FileZilla for example)
   
   Otherwise navigate to the file with "cd /path/to/package/" in the terminal

5) Set the timezone of the server
   ```
   /usr/sbin/dpkg-reconfigure tzdata
   ```
   Change the system language (optional, en_US.UTF-8 is recommended)
   ```
   /usr/sbin/dpkg-reconfigure locales
   ```
6) Run the installer script
   ```
   curl -s https://raw.githubusercontent.com/FZsolter-WAGO/wms-linux-framework/main/bin/install.sh | bash
   ```
   
   If something went wrong, or the password is lost then execute this line again. It will start over the non-framework related part of the installation (dropping the databases and user, cleaning /var/www)
7) Continue with WMS's normal self-host install process
8) Run the post config script
   ```
   wms_post_config
   ```
9) Access the management site at http://<server_ip>.<management_port>/

### Tip 1
This should be used only once during the initial setup of the system, since the recommended way of installing WAGO Monitoring Solution on Linux is using a fresh new minimized OS install on a dedicated hardware only for this one purpose.
### Tip 2
You may also want to use the WMS server as an NTP server for the data collector PLCs. You could install the package NTP. Edit the file /etc/ntp.conf on demand.
```
apt install ntp
```
