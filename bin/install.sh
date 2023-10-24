#!/bin/bash
#####################################################################
#                                                                   #
#   WMS Linux framework installer for Debian 11 (bullseye),         #
#   10 (buster) or Ubuntu 22.04 (jammy)                             #
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
#   1.0.0   -   Initial release                                     #
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
readonly SUPPORTED_WMS_VERSIONS=("3.4.0" "3.4.1")

echo -e ""
echo -e "${GN}WMS Linux framework and software installer for Debian 11 (bullseye), 10 (buster) or Ubuntu 22.04 (jammy)${NC}"
# apt will be used and many other things
# Only root can run the script
if [ "$EUID" -ne 0 ]
then
    echo -e "${RD}[ERR]${NC} Please run as root"
    exit -1
fi
if test -f /var/www/wattson/.env.local
then
    echo -e "${RD}[ERR]${NC} WMS already installed! Create backups manualy, then remove /var/www/wattson folder to use this script"
    exit -1
fi
# The script only works if there is a wms_X.tar.gz package provided by the user in the current directory
echo -e "${YW}[INFO]${NC} Looking for ./wms_X.tar.gz"
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
        echo -e "${YW}[INFO]${NC} Found wms_${version}tar.gz"
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
echo -e "${YW}!!! It will also purge any existing WMS installation (dropping databases, removing /var/www/wattson) !!!${NC}"
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
# We know that Debian dists need to be appended with a PHP repository
CURRENT_DIST="$(lsb_release -sc 2>/dev/null)"
case "$CURRENT_DIST" in
    bullseye|buster)
    echo -e "${YW}[INFO]${NC} Debian detected"
    echo -e "${YW}[INFO]${NC} Installing deb.sury.org for PHP8.1"
    apt -qq -y install ca-certificates curl &>/dev/null
    if [ -z "$(which curl 2>/dev/null)" ]
    then
        echo -e "${RD}[ERR]${NC} Could not install curl!"
        exit -1
    fi
    rm /usr/share/keyrings/deb.sury.org-php.gpg -f &>/dev/null
    rm /etc/apt/sources.list.d/php.list -f &>/dev/null
    curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg &>/dev/null
    echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list
    apt -qq update &>/dev/null
    ;;
    jammy)
    echo -e "${YW}[INFO]${NC} Ubuntu 22.04 jammy detected"
    ;;
    *)
    echo -e "${RD}[ERR]${NC} Only Debian 10 buster or 11 bullseye and Ubuntu 22.04 jammy are supported"
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
    curl -sSLo ./mysql-apt-config.deb https://dev.mysql.com/get/mysql-apt-config_0.8.26-1_all.deb &>/dev/null
    dpkg -i ./mysql-apt-config.deb &>/dev/null
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
# Copypaste from the installation manual. Many of these are already installed, or does not exist at all.
apt -qq install -y php8.1-amqp &>/dev/null
apt -qq install -y php8.1-apc &>/dev/null
apt -qq install -y php8.1-apcu &>/dev/null
apt -qq install -y php8.1-bcmath &>/dev/null
apt -qq install -y php8.1-bz2 &>/dev/null
apt -qq install -y php8.1-calendar &>/dev/null
apt -qq install -y php8.1-Core &>/dev/null
apt -qq install -y php8.1-ctype &>/dev/null
apt -qq install -y php8.1-curl &>/dev/null
apt -qq install -y php8.1-date &>/dev/null
apt -qq install -y php8.1-dom &>/dev/null
apt -qq install -y php8.1-exif &>/dev/null
apt -qq install -y php8.1-FFI &>/dev/null
apt -qq install -y php8.1-fileinfo &>/dev/null
apt -qq install -y php8.1-filter &>/dev/null
apt -qq install -y php8.1-ftp &>/dev/null
apt -qq install -y php8.1-gd &>/dev/null
apt -qq install -y php8.1-gettext &>/dev/null
apt -qq install -y php8.1-hash &>/dev/null
apt -qq install -y php8.1-iconv &>/dev/null
apt -qq install -y php8.1-imagick &>/dev/null
apt -qq install -y php8.1-intl &>/dev/null
apt -qq install -y php8.1-json &>/dev/null
apt -qq install -y php8.1-libxml &>/dev/null
apt -qq install -y php8.1-mbstring &>/dev/null
apt -qq install -y php8.1-memcache &>/dev/null
apt -qq install -y php8.1-mysqli &>/dev/null
apt -qq install -y php8.1-mysqlnd &>/dev/null
apt -qq install -y php8.1-openssl &>/dev/null
apt -qq install -y php8.1-pcntl &>/dev/null
apt -qq install -y php8.1-pcre &>/dev/null
apt -qq install -y php8.1-PDO &>/dev/null
apt -qq install -y php8.1-pdo_mysql &>/dev/null
apt -qq install -y php8.1-pdo_sqlite &>/dev/null
apt -qq install -y php8.1-Phar &>/dev/null
apt -qq install -y php8.1-posix &>/dev/null
apt -qq install -y php8.1-readline &>/dev/null
apt -qq install -y php8.1-Reflection &>/dev/null
apt -qq install -y php8.1-session &>/dev/null
apt -qq install -y php8.1-shmop &>/dev/null
apt -qq install -y php8.1-SimpleXML &>/dev/null
apt -qq install -y php8.1-sockets &>/dev/null
apt -qq install -y php8.1-sodium &>/dev/null
apt -qq install -y php8.1-SPL &>/dev/null
apt -qq install -y php8.1-sqlite3 &>/dev/null
apt -qq install -y php8.1-standard &>/dev/null
apt -qq install -y php8.1-sysvmsg &>/dev/null
apt -qq install -y php8.1-sysvsem &>/dev/null
apt -qq install -y php8.1-sysvshm &>/dev/null
apt -qq install -y php8.1-tokenizer &>/dev/null
apt -qq install -y php8.1-xdebug &>/dev/null
apt -qq install -y php8.1-xml &>/dev/null
apt -qq install -y php8.1-xmlreader &>/dev/null
apt -qq install -y php8.1-xmlwriter &>/dev/null
apt -qq install -y php8.1-xsl &>/dev/null
apt -qq install -y php8.1-zip &>/dev/null
apt -qq install -y php8.1-zlib &>/dev/null

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

# Let's drop the user if it exists, and recreate it with a random password
echo -e "${YW}[INFO]${NC} Setting up MySQL"
if [ -z "$(which mysql 2>/dev/null)" ]
then
    echo -e "${RD}[ERR]${NC} Could not install MySQL!"
    exit -1
fi
mysql -u root -Bse "DROP USER 'wattson'@'localhost';" &>/dev/null
mysql -u root -Bse "DROP USER 'wms'@'localhost';" &>/dev/null
mysql -u root -Bse "DROP DATABASE wattson_system;" &>/dev/null
mysql -u root -Bse "DROP DATABASE wattson_management;" &>/dev/null
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
if [ -z "$(grep -n 'extension=ixed.8.1.lin' /etc/php/8.1/cli/php.ini 2>/dev/null)" ]
then
    echo "extension=ixed.8.1.lin" >> /etc/php/8.1/cli/php.ini
fi
sed -i 's/.*memory_limit.*/memory_limit = -1/' /etc/php/8.1/cli/php.ini &>/dev/null

# Everything should be fine, we can continue with the WMS self-host installation
echo -e "${YW}[INFO]${NC} New database user created: 'wms'@'localhost' IDENTIFIED BY '${YW}$MYSQL_PASS${NC}'"

# Framework install completed, continue with WMS
echo -e "${YW}[INFO]${NC} Unpacking package to /var/www/wattson"
if [ -z "$(which tar 2>/dev/null)" ]
then
    echo -e "${YW}[INFO]${NC} Installing tar and gzip"
    apt -qq install -y tar gzip &>/dev/null
    exit -1
fi
rm /var/www/wattson -Rf &>/dev/null
tar -zxf $FOUND_PACKAGE -C /var/www/ &>/dev/null

echo -e "${YW}[INFO]${NC} Downloading the newest version of wms_post_config to /bin/"
curl -sSLo /bin/wms_post_config https://raw.githubusercontent.com/FZsolter-WAGO/wms-linux-framework/main/src/wms_post_config &>/dev/null
chmod 700 /bin/wms_post_config

# Let's start with the documented WMS installation
cd /var/www/wattson
echo -e "${YW}[INFO]${NC} You have to run 'php bin/console app:installer:self-hosted-install --env=dev' inside /var/www/wattson, you are on your own now..."
echo -e "${YW}[INFO]${NC} This installer terminates here, continue the process manually"
echo -e ""
exit 0

}

# Wrapper function added in 1.0.2
wms_framework_installer
