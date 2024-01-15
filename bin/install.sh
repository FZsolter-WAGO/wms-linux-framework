#!/bin/bash
#####################################################################
#                                                                   #
#   WMS Linux framework installer for Ubuntu 22.04 (jammy)          #
#                                                                   #
#   This script should prepare an enviroment for WAGO Monitoring    #
#   Solution by installing all the mandatory framework softwares,   #
#   and also it should set them up as recommended by the generic    #
#   installation guide.                                             #
#                                                                   #
#   Contact:                                                        #
#   WAGO Hungária Kft.                                              #
#   <zsolt.fekete@wago.com>                                         #
#   <support.hu@wago.com>                                           #
#                                                                   #
#   Version history:                                                #
#   1.0.0   -   Initial release                                     #_
#               PHP8.1 + Apache2 + MariaDB                          #
#               Installing every needed PHP8.1 modules              #
#               Removing the default /var/www/html site from        #
#                   Apache2                                         #
#               Creating a MariaDB 'wattson'@'localhost' user       #
#                   with a random password for the app              #
#                                                                   #
#   1.0.1   -   Day two of working on this script                   #
#               Now the script only runs if it can find the tar.gz  #
#                   WattsON self-host installer package. This has   #
#                   to be provided by the user.                     #
#                                                                   #
#   1.0.2   -   Things I have learnt from get.docker.com            #
#               Warp up the whole script into a function, so the    #
#                   user is protected if the file is not            #
#                   downloaded correctly                            #
#                                                                   #
#   1.0.3   -   New week, new ideas                                 #
#               wattson_post_config added to /bin/                  #
#                                                                   #
#   1.0.4   -   Cosmetics                                           #
#               Modified snek to fit into 80 charaters              #
#                                                                   #
#   1.0.5   -   18 char random password instead of 12 for MariaDB   #
#                                                                   #
#   1.0.6   -   Special characters are no longer allowed            #
#                   for passwords (base64 -> hex)                   #
#                                                                   #
#   2.0.0   -   Software renamed from WattsON Energy                #
#                   to WAGO Monitoring Solution                     #
#               Dropped MariaDB, using MySQL from now               #
#               Enabling ssl mod for Apache2 just in case           #
#                                                                   #
#   2.0.1   -   wms_post_config now generates a fresh password      #
#                   for 'management@wattson.local'                  #
#                                                                   #
#   2.0.2   -   More things renamed to WMS                          #
#                                                                   #
#   2.0.3   -   chmod fix and updating MySQL apt repo               #
#                                                                   #
#   2.0.4   -   Increasing Apache2 PHP execution timeout            #
#                                                                   #
#   2.0.5   -   gnupg needed for MySQL installation                 #
#                                                                   #
#   2.0.6   -   Update to mysql-apt-config_0.8.29-1_all.deb         #
#                                                                   #
#   2.0.7   -   Debian 10 buster is no longer supported             #
#                                                                   #
#   2.0.8   -   Debian is not supported at all currently            #
#                                                                   #
#####################################################################

# Wrapper function added in 1.0.2
function wms_framework_installer {

export DEBIAN_FRONTEND="noninteractive";
# Global color variables
GN='\033[0;32m'
YW='\033[0;33m'
RD='\033[0;31m'
NC='\033[0m'

# Global constants
readonly SUPPORTED_WMS_VERSIONS=("3.4.4" "3.5.4")

echo -e ""
echo -e "${GN}WMS Linux framework and software installer for Ubuntu 22.04 (jammy)${NC}"
# apt will be used and many other things
# Only root can run the script
if [ "$EUID" -ne 0 ]
then
    echo -e "${RD}[ERR]${NC} Please run as root"
    exit -1
fi
if test -f /var/www/wattson/.env.local
then
    echo -e "${RD}[ERR]${NC} Older WattsON instance already installed! Create backups manualy, then remove /var/www/wattson folder to use this script"
    exit -1
fi
if test -f /var/www/wms/.env.local
then
    echo -e "${RD}[ERR]${NC} WMS already installed! Create backups manualy, then remove /var/www/wms folder to use this script"
    exit -1
fi
# The script only works if there is a wms_X.tar.gz package provided by the user in the current directory
echo -e "${YW}[INFO]${NC} Looking for ./wms_X.tar.gz"
# If the script finds a wattson_X.tar.gz, then it runs the new https://github.com/FZsolter-WAGO/wattson-linux-framework/blob/main/bin/install.sh script
FOUND_PACKAGE=$(ls ./ 2>/dev/null | grep wattson_ | grep .tar.gz | tail -1)
if [ -n "$FOUND_PACKAGE" ]
then
    echo -e "${YW}[INFO]${NC} The provided package is for WattsON. Redirecting installer script to https://github.com/FZsolter-WAGO/wattson-linux-framework/blob/main/bin/install.sh"
    curl -s https://github.com/FZsolter-WAGO/wattson-linux-framework/blob/main/bin/install.sh | bash
    exit 0
fi
FOUND_PACKAGE=$(ls ./ 2>/dev/null | grep wms_ | grep .tar.gz | tail -1)
if [ -z "$FOUND_PACKAGE" ]
then
    echo -e "${RD}[ERR]${NC} Can not find package"
    exit -1
fi
FOUND_PACKAGE=./"$FOUND_PACKAGE"
match=false
# Checking for supported versions in the filename
for version in "_${SUPPORTED_WMS_VERSIONS[@]/%/.}"; do
    if [[ $FOUND_PACKAGE == *"$version"* ]]; then
        echo -e "${YW}[INFO]${NC} Found wms${version}tar.gz"
        match=true
        break
    fi
done
if ! $match
then
    echo -e "${RD}[ERR]${NC} No supported version found"
    exit -1
fi

echo -e "${YW}Are you sure about running this script? It will install several packages via apt.${NC}"
echo -e "${YW}!!! It will also purge any existing WMS installation (dropping databases, removing /var/www/wms and /var/www/wattson) !!!${NC}"
echo -e "${YW}Terminate with Ctrl+C to cancel, or wait 20 seconds to continue${NC}"
# The only user input we need, a consent
sleep 10
echo -e "${YW}[INFO]${NC} 10"
sleep 5
echo -e "${YW}[INFO]${NC} 5"
sleep 1
echo -e "${YW}[INFO]${NC} 4"
sleep 1
echo -e "${YW}[INFO]${NC} 3"
sleep 1
echo -e "${YW}[INFO]${NC} 2"
sleep 1
echo -e "${YW}[INFO]${NC} 1"
sleep 1
echo -e "${GN}[SNEK]${NC} ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
${GN}[SNEK]${NC} ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡤⠂⠀⠀
${GN}[SNEK]${NC} ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⠖⠋⠀⠀⠀⠀
${GN}[SNEK]${NC} ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣤⣤⣤⣤⣶⣶⣶⣶⣾⣿⣿⣷⣶⣤⣤⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣀⣤⣴⣾⠟⠁⠀⠀⠀⠀⠀⠀
${GN}[SNEK]${NC} ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣶⣶⣶⣶⣶⣶⣶⣶⣿⣿⣿⡿⠿⠟⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀
${GN}[SNEK]${NC} ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⣠⣶⣿⣿⣿⣿⣿⣿⣿⣿⠿⠿⠿⠿⠛⠛⠛⠛⠛⠛⠛⠛⠿⠿⠿⠿⠿⠿⠿⠿⠛⠛⠛⠋⠉⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
${GN}[SNEK]${NC} ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⣶⣾⣿⣿⣿⣿⣿⣿⣿⡿⠿⠛⠋⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
${GN}[SNEK]${NC} ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
${GN}[SNEK]${NC} ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⢿⣿⣿⣿⡿⣿⣿⣿⣿⣷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
${GN}[SNEK]${NC} ⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
${GN}[SNEK]${NC} ⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
${GN}[SNEK]${NC} ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢿⣿⣿⣿⣿⣿⡿⠟⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
${GN}[SNEK]${NC} ⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⡿⠉⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
${GN}[SNEK]${NC} ⠀⠀⠀⠀⠀⠀⠀⠀⣴⣿⠟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
${GN}[SNEK]${NC} ⠀⠀⠀⠀⠀⠀⢠⣾⣿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
${GN}[SNEK]${NC} ⠀⠀⠀⠀⠀⣠⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
${GN}[SNEK]${NC} ⠀⠀⠀⠀⣴⣿⠿⢿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
${GN}[SNEK]${NC} ⠀⠀⠀⠘⠁⠀⠀⢸⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
${GN}[SNEK]${NC} ⠀⠀⠀⠀⠀⠀⠀⠘⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
${GN}[SNEK]${NC} ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
echo -e "${YW}[INFO]${NC} apt update"
if ! apt -qq update &>/dev/null
then
    echo -e "${RD}[ERR]${NC} Unable to update package list"
    exit -1
fi
# Okay, let's do it
# The package list is updated, and we should be able to install softwares as root
if [ -z "$(which lsb_release 2>/dev/null)" ]
then
    echo -e "${YW}[INFO]${NC} Installing lsb-release"
    apt -qq install -y lsb-release &>/dev/null
    if [ -z "$(which lsb_release 2>/dev/null)" ]
    then
        echo -e "${RD}[ERR]${NC} lsb_release not found!"
        exit -1
    fi
fi
# Dist check
CURRENT_DIST="$(lsb_release -sc 2>/dev/null)"
case "$CURRENT_DIST" in
    jammy)
    echo -e "${YW}[INFO]${NC} Ubuntu 22.04 jammy detected"
    ;;
    *)
    echo -e "${RD}[ERR]${NC} Only Ubuntu 22.04 jammy is supported"
    exit -1
    ;;
esac

# Packages are available, let's install them if they are not installed already
if [ -z "$(ls /etc/apache2/ 2>/dev/null)" ]
then
    echo -e "${YW}[INFO]${NC} Installing Apache2"
    apt -qq install -y apache2 &>/dev/null
else
    echo -e "${YW}[INFO]${NC} Apache2 already installed"
fi
if [ -n "$(which mariadb 2>/dev/null)" ]
then
    echo -e "${YW}[INFO]${NC} Uninstalling MariaDB"
    apt -qq purge -y mariadb-server &>/dev/null
fi
if [ -z "$(which mysql 2>/dev/null)" ]
then
    echo -e "${YW}[INFO]${NC} Installing MySQL"
    curl -sSLo ./mysql-apt-config.deb https://dev.mysql.com/get/mysql-apt-config_0.8.29-1_all.deb &>/dev/null
    apt -qq install -y gnupg sudo &>/dev/null
    sudo DEBIAN_FRONTEND=noninteractive dpkg -i ./mysql-apt-config.deb &>/dev/null
    rm ./mysql-apt-config.deb &>/dev/null
    apt -qq update &>/dev/null
    apt -qq install mysql-server -y &>/dev/null
else
    echo -e "${YW}[INFO]${NC} MySQL already installed"
fi
if [ -z "$(which php8.1 2>/dev/null)" ]
then
    echo -e "${YW}[INFO]${NC} Installing PHP8.1 and the required extensions"
    apt -qq install -y php8.1 &>/dev/null
else
    echo -e "${YW}[INFO]${NC} PHP8.1 already installed"
fi
# The PHP extension install line will run every time, since it is a bit harder to check for them one-by-one
apt -qq install -y php8.1-amqp php8.1-apcu php8.1-bcmath php8.1-bz2 php8.1-calendar php8.1-ctype php8.1-curl php8.1-dom php8.1-exif php8.1-FFI php8.1-fileinfo php8.1-ftp php8.1-gd php8.1-gettext php8.1-iconv php8.1-imagick php8.1-intl php8.1-mbstring php8.1-memcache php8.1-mysqli php8.1-mysqlnd php8.1-PDO php8.1-Phar php8.1-posix php8.1-readline php8.1-shmop php8.1-SimpleXML php8.1-sockets php8.1-sqlite3 php8.1-sysvmsg php8.1-sysvsem php8.1-sysvshm php8.1-tokenizer php8.1-xdebug php8.1-xml php8.1-xmlreader php8.1-xmlwriter php8.1-xsl php8.1-zip &>/dev/null

# Modifying configuration files, and other settings
echo -e "${YW}[INFO]${NC} Setting up Apache2"
if [ -z "$(ls /usr/sbin/ | grep a2en 2>/dev/null)" ]
then
    echo -e "${RD}[ERR]${NC} Could not install Apache2!"
    exit -1
fi
if [ -z "$(grep -n 'ServerName 127.0.0.1' /etc/apache2/apache2.conf 2>/dev/null)" ]
then
    echo "ServerName 127.0.0.1" >> /etc/apache2/apache2.conf
fi
/usr/sbin/a2enmod php8.1 rewrite alias setenvif socache_shmcb ssl &>/dev/null
# The default 80 and 443 ports are used by the default example sites provided by the vendor. Removing them.
if [ -n "$(ls /etc/apache2/sites-available/ 2>/dev/null)" ]
then
    /usr/sbin/a2dissite $(ls /etc/apache2/sites-available/) &>/dev/null
fi
rm /etc/apache2/sites-available/* &>/dev/null
echo "" > /etc/apache2/ports.conf
rm /var/www/html -rf

# Let's drop the user if it exists, and recreate it with a random password
echo -e "${YW}[INFO]${NC} Setting up MySQL"
if [ -z "$(which mysql 2>/dev/null)" ]
then
    echo -e "${RD}[ERR]${NC} Could not install MySQL!"
    exit -1
fi
mysql -u root -Bse "DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';" &>/dev/null
mysql -u root -Bse "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');" &>/dev/null
mysql -u root -Bse "DELETE FROM mysql.user WHERE User='';" &>/dev/null
mysql -u root -Bse "DELETE FROM mysql.user WHERE User='wattson';" &>/dev/null
mysql -u root -Bse "DELETE FROM mysql.user WHERE User='wms';" &>/dev/null
mysql -u root -Bse "FLUSH PRIVILEGES;" &>/dev/null
mysql -u root -Bse "DROP DATABASE wattson_system;" &>/dev/null
mysql -u root -Bse "DROP DATABASE wattson_management;" &>/dev/null
mysql -u root -Bse "DROP DATABASE wms_system;" &>/dev/null
mysql -u root -Bse "DROP DATABASE wms_management;" &>/dev/null
MYSQL_PASS="$(openssl rand -hex 18)"
mysql -u root -Bse "CREATE USER 'wms'@'localhost' IDENTIFIED BY '$MYSQL_PASS';GRANT ALL ON *.* TO 'wms'@'localhost';" &>/dev/null

# The php.ini files have to be modified, and we must provide the SourceGuardian loader
echo -e "${YW}[INFO]${NC} Setting up PHP8.1"
curl -sSLo /usr/lib/php/20210902/ixed.8.1.lin https://raw.githubusercontent.com/FZsolter-WAGO/wms-linux-framework/main/src/ixed.8.1.lin &>/dev/null
if [ -z "$(grep -n 'extension=ixed.8.1.lin' /etc/php/8.1/apache2/php.ini 2>/dev/null)" ]
then
    echo "extension=ixed.8.1.lin" >> /etc/php/8.1/apache2/php.ini
fi
sed -i 's/.*upload_max_filesize.*/upload_max_filesize = 256M/' /etc/php/8.1/apache2/php.ini &>/dev/null
sed -i 's/.*post_max_size = .*/post_max_size = 512M/' /etc/php/8.1/apache2/php.ini &>/dev/null
sed -i 's/.*memory_limit = .*/memory_limit = 1024M/' /etc/php/8.1/apache2/php.ini &>/dev/null
sed -i 's/.*max_input_vars = .*/max_input_vars = 1000/' /etc/php/8.1/apache2/php.ini &>/dev/null
sed -i 's/.*file_uploads = O.*/file_uploads = On/' /etc/php/8.1/apache2/php.ini &>/dev/null
sed -i 's/.*max_execution_time = .*/max_execution_time = 120/' /etc/php/8.1/apache2/php.ini &>/dev/null
if [ -z "$(grep -n 'extension=ixed.8.1.lin' /etc/php/8.1/cli/php.ini 2>/dev/null)" ]
then
    echo "extension=ixed.8.1.lin" >> /etc/php/8.1/cli/php.ini
fi
sed -i 's/.*memory_limit.*/memory_limit = -1/' /etc/php/8.1/cli/php.ini &>/dev/null

# Everything should be fine, we can continue with the WMS self-host installation
echo -e "${YW}[INFO]${NC} New database user created: 'wms'@'localhost' IDENTIFIED BY '${YW}$MYSQL_PASS${NC}'"

# Framework install completed, continue with WMS
echo -e "${YW}[INFO]${NC} Unpacking package to /var/www/wms"
if [ -z "$(which tar 2>/dev/null)" ]
then
    echo -e "${YW}[INFO]${NC} Installing tar and gzip"
    apt -qq install -y tar gzip &>/dev/null
    exit -1
fi
rm /var/www/wattson -Rf &>/dev/null
rm /var/www/wms -Rf &>/dev/null
chown root:www-data -R /var/www &>/dev/null
tar -zxf $FOUND_PACKAGE -C /var/www/ &>/dev/null
mv /var/www/wattson /var/www/wms &>/dev/null

echo -e "${YW}[INFO]${NC} Downloading the newest version of wms_post_config to /bin/"
curl -sSLo /bin/wms_post_config https://raw.githubusercontent.com/FZsolter-WAGO/wms-linux-framework/main/src/wms_post_config &>/dev/null
chmod 700 /bin/wms_post_config

# Let's start with the documented WMS installation
cd /var/www/wms
echo -e "${YW}[INFO]${NC} You have to run '${YW}php bin/console app:installer:self-hosted-install --env=dev${NC}' inside /var/www/wms, you are on your own now..."
echo -e "${YW}[INFO]${NC} This installer terminates here, continue the process manually"
echo -e ""
exit 0

}

# Wrapper function added in 1.0.2
wms_framework_installer
