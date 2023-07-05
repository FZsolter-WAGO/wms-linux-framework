#!/bin/sh
#####################################################################
#                                                                   #
#   WattsON Linux framework installer for Debian 11 (bullseye)      #
#   or Ubuntu 22.04 (jammy)                                         #
#                                                                   #
#   This script should prepare an enviroment for WattsON Energy     #
#   by installing all the mandatory framework softwares, and        #
#   also it should set them up as recommended by the generic        #
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
#####################################################################

# Global color variables
GN='\033[0;32m'
YW='\033[0;33m'
RD='\033[0;31m'
NC='\033[0m'

echo -e ""
echo -e "${GN}WattsON Linux framework installer for Debian 11 (bullseye), 10 (bullseye) or Ubuntu 22.04 (jammy)${NC}"
echo -e "${YW}Are you sure about running this script? It will install several packages via apt.${NC} (y/n)"
# The only user input we need, a consent
read answer
case $answer in
    y|Y)
    ;;
    *)
    echo -e "${RD}[ERR]${NC} Installation canceled"
    exit -1
    ;;
esac

# apt will be used and many other things
# Only root can run the script
if [ "$EUID" -ne 0 ]
then
    echo -e "${RD}[ERR]${NC} Please run as root"
    exit -1
fi
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
if [ -z "$(which mariadb 2>/dev/null)" ]
then
    echo -e "${YW}[INFO]${NC} Installing MariaDB"
    apt -qq install -y mariadb-server &>/dev/null
else
    echo -e "${YW}[INFO]${NC} MariaDB already installed"
fi
if [ -z "$(which php8.1 2>/dev/null)" ]
then
    echo -e "${YW}[INFO]${NC} Installing PHP8.1 and the required extensions"
    apt -qq install -y php8.1 &>/dev/null
else
    echo -e "${YW}[INFO]${NC} PHP8.1 already installed"
fi
# The PHP extension install line will run every time, since it is a bit harder to check for them one-by-one
apt -qq install -y php8.1-amqp php8.1-apcu php8.1-bz2 php8.1-bcmath php8.1-curl php8.1-gd php8.1-imagick php8.1-intl php8.1-mbstring php8.1-memcache php8.1-mysql php8.1-sqlite3 php8.1-SimpleXML php8.1-xdebug php8.1-xml php8.1-zip &>/dev/null

# Modifying configuration files, and other settings
echo -e "${YW}[INFO]${NC} Setting up Apache2"
if [ -z "$(ls /usr/sbin/ | grep a2en 2>/dev/null)" ]
then
    echo -e "${RD}[ERR]${NC} Could not install Apache2!"
    exit -1
fi
if [ -z "$(grep -n 'ServerName 127.0.0.1' /etc/apache2/apache2.conf 2>/dev/null)" ]
then
    echo "ServerName 127.0.0.1" >> /etc/apache2/apache2.conf &>/dev/null
fi
/usr/sbin/a2enmod php8.1 rewrite alias setenvif socache_shmcb &>/dev/null
# The default 80 and 443 ports are used by the default example sites provided by the vendor. Removing them.
if [ -n "$(ls /etc/apache2/sites-available/ 2>/dev/null)" ]
then
    /usr/sbin/a2dissite $(ls /etc/apache2/sites-available/) &>/dev/null
fi
rm /etc/apache2/sites-available/* &>/dev/null
echo "" > /etc/apache2/ports.conf &>/dev/null

# Let's drop the user if it exists, and recreate it with a random password
echo -e "${YW}[INFO]${NC} Setting up MariaDB"
if [ -z "$(which mysql 2>/dev/null)" ]
then
    echo -e "${RD}[ERR]${NC} Could not install MariaDB!"
    exit -1
fi
mysql -u root -Bse "DROP USER 'wattson'@'localhost';" &>/dev/null
MYSQL_PASS="$(openssl rand -base64 12)"
mysql -u root -Bse "CREATE USER 'wattson'@'localhost' IDENTIFIED BY '$MYSQL_PASS';GRANT ALL ON *.* TO 'wattson'@'localhost';" &>/dev/null

# The php.ini files have to be modified, and we must provide the SourceGuardian loader
echo -e "${YW}[INFO]${NC} Setting up PHP8.1"
curl -sSLo /usr/lib/php/20210902/ixed.8.1.lin https://raw.githubusercontent.com/FZsolter-WAGO/wattson-linux-framework/main/src/ixed.8.1.lin &>/dev/null
echo "extension=ixed.8.1.lin" >> /etc/php/8.1/apache2/php.ini &>/dev/null
sed -i 's/.*upload_max_filesize.*/upload_max_filesize = 256M/' /etc/php/8.1/apache2/php.ini &>/dev/null
sed -i 's/.*post_max_size = .*/post_max_size = 512M/' /etc/php/8.1/apache2/php.ini &>/dev/null
sed -i 's/.*memory_limit = .*/memory_limit = 1024M/' /etc/php/8.1/apache2/php.ini &>/dev/null
sed -i 's/.*max_input_vars = .*/max_input_vars = 1000/' /etc/php/8.1/apache2/php.ini &>/dev/null
sed -i 's/.*file_uploads = O.*/file_uploads = On/' /etc/php/8.1/apache2/php.ini &>/dev/null
echo "extension=ixed.8.1.lin" >> /etc/php/8.1/cli/php.ini &>/dev/null
sed -i 's/.*memory_limit.*/memory_limit = -1/' /etc/php/8.1/cli/php.ini &>/dev/null

# Everything should be fine, we can continue with the WattsON self-host installation
echo -e "${GN}[OK]${NC} Done! New database user created: 'wattson'@'localhost' IDENTIFIED BY '${YW}$MYSQL_PASS${NC}'"
echo -e ""
exit 0
