﻿# WattsON Energy Linux framework installer

## Only Debian 10/11 and Ubuntu 22.04 are supported!

Anything can have a mascot

![snek](snek.png)

### Usage

To run the following command:
1) Configure network settings to access the Internet

   It is recommended to use a br0 bridge interface with a static MAC address of the primary physical interface (br0=X1+X2 with the MAC of X1)
3) Remove any Docker installation (docker0 network interface keeps changing it's MAC address and therefore the hardware key needed for licensing keeps changing on every reboot)
   ```
   apt purge docker* -y && apt autoremove -y
   ```
4) Update the system, and install curl and sudo
   ```
   apt update && apt full-upgrade -y && apt install curl sudo -y
   ```
5) Run the installer script
   ```
   curl -s https://raw.githubusercontent.com/FZsolter-WAGO/wattson-linux-framework/main/bin/install.sh | sudo bash
   ```
6) Continue with WattsON's normal self-host install process
7) Run the post config script
   ```
   sudo wattson_post_config
   ```
8) Access the management site at http://<server_ip>.<management_port>/

### Tip
This should be used only once during the initial setup of the system, since the recommended way of installing WattsON Energy on Linux is using a fresh new minimized OS install on a dedicated hardware only for this one purpose.
