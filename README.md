# WattsON Energy Linux framework installer

## Only Debian 10/11 and Ubuntu 22.04 are supported!

Anything can have a mascot

![snek](snek.png)

### Usage

To run the following command:
1) Configure network settings to access the Internet
2) Install curl and sudo (apt install curl sudo)
3) Remove any docker installation (docker0 network interface keeps changing it's MAC address)

```
curl -s https://raw.githubusercontent.com/FZsolter-WAGO/wattson-linux-framework/main/bin/install.sh | sudo bash
```
### Tip
This should be used only once during the initial setup of the system, since the recommended way of installing WattsON Energy on Linux is using a fresh new minimized OS install on a dedicated hardware only for this one purpose.
