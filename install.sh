#!/bin/bash
###############################################################################################
# Complete ISPConfig setup script for Debian 6.		 										  #
# Drew Clardy																				  #
# http://drewclardy.com							                                              #
###############################################################################################


#Edit values below before using script
MYSQL_ROOT_PASSWORD=abcd1234
HOSTNAME=abc
HOSTNAMEFQDN=abc.def.com
serverIP=123.456.78.9
sshd_port=1234
#Choose country that is closest to your server. ( us, de, uk, ru, jp, au, nz  )
APTregion=us

###Functions Begin###

function basic_server_setup {

#Reconfigure sshd - change port
sed -i 's/^Port [0-9]*/Port '${sshd_port}'/' /etc/ssh/sshd_config
/etc/init.d/ssh reload

#Set hostname and FQDN
sed -i 's/'${serverIP}'.*/'${serverIP}' '${HOSTNAMEFQDN}' '${HOSTNAME}'/' /etc/hosts
echo "$HOSTNAME" > /etc/hostname
/etc/init.d/hostname.sh start >/dev/null 2>&1

#Remove broken libpam-krb5
apt-get -y remove --purge libpam-krb5

#Updates server and install commonly used utilities
aptitude update
aptitude -y safe-upgrade
aptitude -y install vim-nox htop lynx dnsutils unzip 

} #end function basic_server_setup


function install_ISPConfigBCNQ {
#Reconfigure Dash
dpkg-reconfigure dash
#Use dash as the default system shell (/bin/sh)? <-- No

#Synchronize the System Clock
apt-get -y install ntp ntpdate

#Install Postfix, Courier, Saslauthd, MySQL, phpMyAdmin, rkhunter, binutils
echo "mysql-server-5.1 mysql-server/root_password password $MYSQL_ROOT_PASSWORD" | debconf-set-selections
echo "mysql-server-5.1 mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD" | debconf-set-selections
echo "postfix	postfix/main_mailer_type	select	Internet Site" | debconf-set-selections
echo "postfix	postfix/mailname	string	${HOSTNAMEFQDN}" | debconf-set-selections
echo "courier-base	courier-base/webadmin-configmode	boolean	false" | debconf-set-selections
echo "courier-ssl	courier-ssl/certnotice	note" | debconf-set-selections
echo "phpmyadmin      phpmyadmin/dbconfig-install     boolean false" | debconf-set-selections
echo "phpmyadmin      phpmyadmin/reconfigure-webserver        multiselect     apache2" | debconf-set-selections
apt-get -y install postfix postfix-mysql postfix-doc mysql-client mysql-server courier-authdaemon courier-authlib-mysql courier-pop courier-pop-ssl courier-imap courier-imap-ssl libsasl2-2 libsasl2-modules libsasl2-modules-sql sasl2-bin libpam-mysql openssl courier-maildrop getmail4 rkhunter binutils sudo

#Allow MySQL to listen on all interfaces
sed -i 's/bind-address           = 127.0.0.1/#bind-address           = 127.0.0.1PermitRootLogin no/' /etc/mysql/my.cnf
/etc/init.d/mysql restart

#Delete and Reconfigure SSL Certificates
cd /etc/courier
rm -f /etc/courier/imapd.pem
rm -f /etc/courier/pop3d.pem
sed -i 's/CN=localhost/CN='${HOSTNAMEFQDN}'/' /etc/courier/imapd.cnf
sed -i 's/CN=localhost/CN='${HOSTNAMEFQDN}'/' /etc/courier/pop3d.cnf
mkimapdcert
mkpop3dcert
/etc/init.d/courier-imap-ssl restart
/etc/init.d/courier-pop-ssl restart

#Install Amavisd-new, SpamAssassin, And Clamav
apt-get -y install amavisd-new spamassassin clamav clamav-daemon zoo unzip bzip2 arj nomarch lzop cabextract apt-listchanges libnet-ldap-perl libauthen-sasl-perl clamav-docs daemon libio-string-perl libio-socket-ssl-perl libnet-ident-perl zip libnet-dns-perl

#Install Apache2, PHP5, phpMyAdmin, FCGI, suExec, Pear, And mcrypt
apt-get -y install apache2 apache2.2-common apache2-doc apache2-mpm-prefork apache2-utils libexpat1 ssl-cert libapache2-mod-php5 php5 php5-common php5-gd php5-mysql php5-imap phpmyadmin php5-cli php5-cgi libapache2-mod-fcgid apache2-suexec php-pear php-auth php5-mcrypt mcrypt php5-imagick imagemagick libapache2-mod-suphp libruby libapache2-mod-ruby

#Web server to reconfigure automatically: <-- apache2
#Configure database for phpmyadmin with dbconfig-common? <-- No

a2enmod suexec rewrite ssl actions include
a2enmod dav_fs dav auth_digest

/etc/init.d/apache2 restart

#Install PureFTPd
apt-get -y install pure-ftpd-common pure-ftpd-mysql

#Setting up Pure-Ftpd

sed -i 's/VIRTUALCHROOT=false/VIRTUALCHROOT=true/' /etc/default/pure-ftpd-common
sed -i 's/ftp    stream  tcp     nowait  root    /usr/sbin/tcpd /usr/sbin/pure-ftpd-wrapper/#ftp    stream  tcp     nowait  root    /usr/sbin/tcpd /usr/sbin/pure-ftpd-wrapper/' /etc/inetd.conf
/etc/init.d/openbsd-inetd restart
echo 1 > /etc/pure-ftpd/conf/TLS
mkdir -p /etc/ssl/private/
echo -e "\033[35;1m Generating SSL certs, you do not have to enter any details when asked. But recommended to enter Hostname FQDN for 'Common Name'! \033[0m"
openssl req -x509 -nodes -days 7300 -newkey rsa:2048 -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem
chmod 600 /etc/ssl/private/pure-ftpd.pem
/etc/init.d/pure-ftpd-mysql restart

#Setting up Quota


#Install BIND DNS Server
apt-get -y install bind9 dnsutils

#Install Vlogger, Webalizer, And AWstats
apt-get -y install vlogger webalizer awstats

rm /etc/cron.d/awstats
cat > /etc/cron.d/awstats <<EOF
#*/10 * * * * www-data [ -x /usr/share/awstats/tools/update.sh ] && /usr/share/awstats/tools/update.sh

# Generate static reports:
#10 03 * * * www-data [ -x /usr/share/awstats/tools/buildstatic.sh ] && /usr/share/awstats/tools/buildstatic.sh
EOF


#Install Jailkit
apt-get -y install build-essential autoconf automake1.9 libtool flex bison debhelper

cd /tmp
wget http://olivier.sessink.nl/jailkit/jailkit-2.13.tar.gz
tar xvfz jailkit-2.13.tar.gz
cd jailkit-2.13
./debian/rules binary
cd ..
dpkg -i jailkit_2.13-1_*.deb
rm -rf jailkit-2.13*

#Install fail2ban
apt-get -y install fail2ban

cat > /etc/fail2ban/jail.local <<EOF
[pureftpd]

enabled  = true
port     = ftp
filter   = pureftpd
logpath  = /var/log/syslog
maxretry = 3


[sasl]

enabled  = true
port     = smtp
filter   = sasl
logpath  = /var/log/mail.log
maxretry = 5


[courierpop3]

enabled  = true
port     = pop3
filter   = courierpop3
logpath  = /var/log/mail.log
maxretry = 5


[courierpop3s]

enabled  = true
port     = pop3s
filter   = courierpop3s
logpath  = /var/log/mail.log
maxretry = 5


[courierimap]

enabled  = true
port     = imap2
filter   = courierimap
logpath  = /var/log/mail.log
maxretry = 5


[courierimaps]

enabled  = true
port     = imaps
filter   = courierimaps
logpath  = /var/log/mail.log
maxretry = 5/etc/fail2ban/jail.local

cat > /etc/fail2ban/filter.d/pureftpd.conf <<EOF
[Definition]
failregex = .*pure-ftpd: \(.*@<HOST>\) \[WARNING\] Authentication failed for user.*
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/courierpop3.conf <<EOF
# Fail2Ban configuration file
#
# $Revision: 100 $
#

[Definition]

# Option:  failregex
# Notes.:  regex to match the password failures messages in the logfile. The
#          host must be matched by a group named "host". The tag "<HOST>" can
#          be used for standard IP/hostname matching and is only an alias for
#          (?:::f{4,6}:)?(?P<host>\S+)
# Values:  TEXT
#
failregex = pop3d: LOGIN FAILED.*ip=\[.*:<HOST>\]

# Option:  ignoreregex
# Notes.:  regex to ignore. If this regex matches, the line is ignored.
# Values:  TEXT
#
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/courierpop3s.conf <<EOF
# Fail2Ban configuration file
#
# $Revision: 100 $
#

[Definition]

# Option:  failregex
# Notes.:  regex to match the password failures messages in the logfile. The
#          host must be matched by a group named "host". The tag "<HOST>" can
#          be used for standard IP/hostname matching and is only an alias for
#          (?:::f{4,6}:)?(?P<host>\S+)
# Values:  TEXT
#
failregex = pop3d-ssl: LOGIN FAILED.*ip=\[.*:<HOST>\]

# Option:  ignoreregex
# Notes.:  regex to ignore. If this regex matches, the line is ignored.
# Values:  TEXT
#
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/courierimap.conf <<EOF
# Fail2Ban configuration file
#
# $Revision: 100 $
#

[Definition]

# Option:  failregex
# Notes.:  regex to match the password failures messages in the logfile. The
#          host must be matched by a group named "host". The tag "<HOST>" can
#          be used for standard IP/hostname matching and is only an alias for
#          (?:::f{4,6}:)?(?P<host>\S+)
# Values:  TEXT
#
failregex = imapd: LOGIN FAILED.*ip=\[.*:<HOST>\]

# Option:  ignoreregex
# Notes.:  regex to ignore. If this regex matches, the line is ignored.
# Values:  TEXT
#
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/courierimaps.conf <<EOF
# Fail2Ban configuration file
#
# $Revision: 100 $
#

[Definition]

# Option:  failregex
# Notes.:  regex to match the password failures messages in the logfile. The
#          host must be matched by a group named "host". The tag "<HOST>" can
#          be used for standard IP/hostname matching and is only an alias for
#          (?:::f{4,6}:)?(?P<host>\S+)
# Values:  TEXT
#
failregex = imapd-ssl: LOGIN FAILED.*ip=\[.*:<HOST>\]

# Option:  ignoreregex
# Notes.:  regex to ignore. If this regex matches, the line is ignored.
# Values:  TEXT
#
ignoreregex =
EOF

/etc/init.d/fail2ban restart

#Install SquirrelMail
apt-get -y install squirrelmail
ln -s /usr/share/squirrelmail/ /var/www/webmail
echo -e "\033[35;1m Select D, type courier, press a key, Type S, and Quit! \033[0m"
squirrelmail-configure

#Install ISPConfig 3
cd /tmp
wget http://www.ispconfig.org/downloads/ISPConfig-3-stable.tar.gz
tar xfz ISPConfig-3-stable.tar.gz
cd ispconfig3_install/install/
php -q install.php


} #install_ISPConfigBCNQ

function install_ISPConfigBC {
#Reconfigure Dash
dpkg-reconfigure dash
#Use dash as the default system shell (/bin/sh)? <-- No

#Synchronize the System Clock
apt-get -y install ntp ntpdate

#Install Postfix, Courier, Saslauthd, MySQL, phpMyAdmin, rkhunter, binutils
echo "mysql-server-5.1 mysql-server/root_password password $MYSQL_ROOT_PASSWORD" | debconf-set-selections
echo "mysql-server-5.1 mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD" | debconf-set-selections
echo "phpmyadmin      phpmyadmin/dbconfig-install     boolean false" | debconf-set-selections
echo "phpmyadmin      phpmyadmin/reconfigure-webserver        multiselect     apache2" | debconf-set-selections
apt-get -y install postfix postfix-mysql postfix-doc mysql-client mysql-server courier-authdaemon courier-authlib-mysql courier-pop courier-pop-ssl courier-imap courier-imap-ssl libsasl2-2 libsasl2-modules libsasl2-modules-sql sasl2-bin libpam-mysql openssl courier-maildrop getmail4 rkhunter binutils sudo

#Allow MySQL to listen on all interfaces
sed -i 's/bind-address           = 127.0.0.1/#bind-address           = 127.0.0.1PermitRootLogin no/' /etc/mysql/my.cnf
/etc/init.d/mysql restart

#Delete and Reconfigure SSL Certificates
cd /etc/courier
rm -f /etc/courier/imapd.pem
rm -f /etc/courier/pop3d.pem
sed -i 's/CN=localhost/CN='${HOSTNAMEFQDN}'/' /etc/courier/imapd.cnf
sed -i 's/CN=localhost/CN='${HOSTNAMEFQDN}'/' /etc/courier/pop3d.cnf
mkimapdcert
mkpop3dcert
/etc/init.d/courier-imap-ssl restart
/etc/init.d/courier-pop-ssl restart

#Install Amavisd-new, SpamAssassin, And Clamav
apt-get -y install amavisd-new spamassassin clamav clamav-daemon zoo unzip bzip2 arj nomarch lzop cabextract apt-listchanges libnet-ldap-perl libauthen-sasl-perl clamav-docs daemon libio-string-perl libio-socket-ssl-perl libnet-ident-perl zip libnet-dns-perl

#Install Apache2, PHP5, phpMyAdmin, FCGI, suExec, Pear, And mcrypt
echo -e "\033[35;1m Select Apache 2 for automatic setup. Select No for using database db-config-common! \033[0m"
apt-get -y install apache2 apache2.2-common apache2-doc apache2-mpm-prefork apache2-utils libexpat1 ssl-cert libapache2-mod-php5 php5 php5-common php5-gd php5-mysql php5-imap phpmyadmin php5-cli php5-cgi libapache2-mod-fcgid apache2-suexec php-pear php-auth php5-mcrypt mcrypt php5-imagick imagemagick libapache2-mod-suphp libruby libapache2-mod-ruby

#Web server to reconfigure automatically: <-- apache2
#Configure database for phpmyadmin with dbconfig-common? <-- No

a2enmod suexec rewrite ssl actions include
a2enmod dav_fs dav auth_digest

/etc/init.d/apache2 restart

#Install PureFTPd
apt-get -y install pure-ftpd-common pure-ftpd-mysql

#Setting up Pure-Ftpd

sed -i 's/VIRTUALCHROOT=false/VIRTUALCHROOT=true/' /etc/default/pure-ftpd-common
sed -i 's/ftp    stream  tcp     nowait  root    /usr/sbin/tcpd /usr/sbin/pure-ftpd-wrapper/#ftp    stream  tcp     nowait  root    /usr/sbin/tcpd /usr/sbin/pure-ftpd-wrapper/' /etc/inetd.conf
/etc/init.d/openbsd-inetd restart
echo 1 > /etc/pure-ftpd/conf/TLS
mkdir -p /etc/ssl/private/
echo -e "\033[35;1m Generating SSL certs, you do not have to enter any details when asked. But recommended to enter Hostname FQDN for 'Common Name'! \033[0m"
openssl req -x509 -nodes -days 7300 -newkey rsa:2048 -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem
chmod 600 /etc/ssl/private/pure-ftpd.pem
/etc/init.d/pure-ftpd-mysql restart

#Setting up Quota

apt-get -y install quota quotatool
mount -o remount /
quotacheck -avugm
quotaon -avug


#Install BIND DNS Server
apt-get -y install bind9 dnsutils

#Install Vlogger, Webalizer, And AWstats
apt-get -y install vlogger webalizer awstats

sed -i 's/*/10 * * * * www-data [ -x /usr/share/awstats/tools/update.sh ] && /usr/share/awstats/tools/update.sh/#*/10 * * * * www-data [ -x /usr/share/awstats/tools/update.sh ] && /usr/share/awstats/tools/update.sh/' /etc/cron.d/awstats
sed -i 's/10 03 * * * www-data [ -x /usr/share/awstats/tools/buildstatic.sh ] && /usr/share/awstats/tools/buildstatic.sh/#10 03 * * * www-data [ -x /usr/share/awstats/tools/buildstatic.sh ] && /usr/share/awstats/tools/buildstatic.sh/' /etc/cron.d/awstats

#Install Jailkit
apt-get -y install build-essential autoconf automake1.9 libtool flex bison debhelper

cd /tmp
wget http://olivier.sessink.nl/jailkit/jailkit-2.13.tar.gz
tar xvfz jailkit-2.13.tar.gz
cd jailkit-2.13
./debian/rules binary
cd ..
dpkg -i jailkit_2.13-1_*.deb
rm -rf jailkit-2.13*

#Install fail2ban
apt-get -y install fail2ban

cat > /etc/fail2ban/jail.local <<EOF
[pureftpd]

enabled  = true
port     = ftp
filter   = pureftpd
logpath  = /var/log/syslog
maxretry = 3


[sasl]

enabled  = true
port     = smtp
filter   = sasl
logpath  = /var/log/mail.log
maxretry = 5


[courierpop3]

enabled  = true
port     = pop3
filter   = courierpop3
logpath  = /var/log/mail.log
maxretry = 5


[courierpop3s]

enabled  = true
port     = pop3s
filter   = courierpop3s
logpath  = /var/log/mail.log
maxretry = 5


[courierimap]

enabled  = true
port     = imap2
filter   = courierimap
logpath  = /var/log/mail.log
maxretry = 5


[courierimaps]

enabled  = true
port     = imaps
filter   = courierimaps
logpath  = /var/log/mail.log
maxretry = 5/etc/fail2ban/jail.local

cat > /etc/fail2ban/filter.d/pureftpd.conf <<EOF
[Definition]
failregex = .*pure-ftpd: \(.*@<HOST>\) \[WARNING\] Authentication failed for user.*
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/courierpop3.conf <<EOF
# Fail2Ban configuration file
#
# $Revision: 100 $
#

[Definition]

# Option:  failregex
# Notes.:  regex to match the password failures messages in the logfile. The
#          host must be matched by a group named "host". The tag "<HOST>" can
#          be used for standard IP/hostname matching and is only an alias for
#          (?:::f{4,6}:)?(?P<host>\S+)
# Values:  TEXT
#
failregex = pop3d: LOGIN FAILED.*ip=\[.*:<HOST>\]

# Option:  ignoreregex
# Notes.:  regex to ignore. If this regex matches, the line is ignored.
# Values:  TEXT
#
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/courierpop3s.conf <<EOF
# Fail2Ban configuration file
#
# $Revision: 100 $
#

[Definition]

# Option:  failregex
# Notes.:  regex to match the password failures messages in the logfile. The
#          host must be matched by a group named "host". The tag "<HOST>" can
#          be used for standard IP/hostname matching and is only an alias for
#          (?:::f{4,6}:)?(?P<host>\S+)
# Values:  TEXT
#
failregex = pop3d-ssl: LOGIN FAILED.*ip=\[.*:<HOST>\]

# Option:  ignoreregex
# Notes.:  regex to ignore. If this regex matches, the line is ignored.
# Values:  TEXT
#
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/courierimap.conf <<EOF
# Fail2Ban configuration file
#
# $Revision: 100 $
#

[Definition]

# Option:  failregex
# Notes.:  regex to match the password failures messages in the logfile. The
#          host must be matched by a group named "host". The tag "<HOST>" can
#          be used for standard IP/hostname matching and is only an alias for
#          (?:::f{4,6}:)?(?P<host>\S+)
# Values:  TEXT
#
failregex = imapd: LOGIN FAILED.*ip=\[.*:<HOST>\]

# Option:  ignoreregex
# Notes.:  regex to ignore. If this regex matches, the line is ignored.
# Values:  TEXT
#
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/courierimaps.conf <<EOF
# Fail2Ban configuration file
#
# $Revision: 100 $
#

[Definition]

# Option:  failregex
# Notes.:  regex to match the password failures messages in the logfile. The
#          host must be matched by a group named "host". The tag "<HOST>" can
#          be used for standard IP/hostname matching and is only an alias for
#          (?:::f{4,6}:)?(?P<host>\S+)
# Values:  TEXT
#
failregex = imapd-ssl: LOGIN FAILED.*ip=\[.*:<HOST>\]

# Option:  ignoreregex
# Notes.:  regex to ignore. If this regex matches, the line is ignored.
# Values:  TEXT
#
ignoreregex =
EOF

/etc/init.d/fail2ban restart

#Install SquirrelMail
apt-get -y install squirrelmail
ln -s /usr/share/squirrelmail/ /var/www/webmail
echo -e "\033[35;1m Select D, type courier, press a key, Type S, and Quit! \033[0m"
squirrelmail-configure

#Install ISPConfig 3
cd /tmp
wget http://www.ispconfig.org/downloads/ISPConfig-3-stable.tar.gz
tar xfz ISPConfig-3-stable.tar.gz
cd ispconfig3_install/install/
php -q install.php


} #install_ISPConfigBC


####Main program begins####
#Show Menu#
if [ ! -n "$1" ]; then
    echo ""
    echo -e  "\033[35;1mIMPORTANT!! Edit script variables at the start of script before executing\033[0m"
    echo -e  "\033[35;1mA standard install would be - basic + ISPCONFIG Choice\033[0m"
    echo ""
    echo -e  "\033[35;1mSelect from the options below to use this script:- \033[0m"
    echo -n  "$0"
    echo -ne "\033[36m basic\033[0m"
    echo     " - Change SSH port, set hostname, installs vim htop lynx dnsutils unzip."

    echo -n "$0"
    echo -ne "\033[36m ISPConfigBCNQ\033[0m"
    echo     " - Installs ISPConfig dependencies with Bind and Courier. No quota enabled."

    echo -n "$0"
    echo -ne "\033[36m ISPConfigBC\033[0m"
    echo     " - Installs ISPConfig dependencies with Bind and Courier. Quota Enabled. Please edit /etc/fstab before running the installer! You need to add ,usrjquota=aquota.user,grpjquota=aquota.group,jqfmt=vfsv0 to the mount point /!"

    echo ""
    exit
fi
#End Show Menu#

#Execute functions#
if [ "$1" = "basic" ]; then
    basic_server_setup
    echo -e "\033[35;1m SSH port set to $sshd_port. Hostname set to $HOSTNAME and FQDN to $HOSTNAMEFQDN. \033[0m"
    echo -e "\033[35;1m Htop, lynx, dnsutils, unzip installed. \033[0m"

elif [ "$1" = "ISPConfigBCNQ" ]; then
    install_ISPConfigBCNQ
    echo -e "\033[35;1m Installation of ISPConfig with Bind/Courier No Quota complete! Enjoy! \033[0m"

elif [ "$1" = "ISPConfigBC" ]; then
    install_ISPConfigBC
    echo -e "\033[35;1m Installation of ISPConfig with Bind/Courier-Quota complete! Enjoy! \033[0m"


fi
#End execute functions#