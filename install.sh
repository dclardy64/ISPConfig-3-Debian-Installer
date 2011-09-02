#!/bin/bash
###############################################################################################
# Complete ISPConfig setup script for Debian 6.		 										  #
# Drew Clardy																				  #
# http://drewclardy.com							                                              #
###############################################################################################

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install the software."
    exit 1
fi

clear
echo "========================================================================="
echo "ISPConfig 3 Setup Script ,  Written by Drew Clardy "
echo "========================================================================="
echo "A tool to auto-install ISPConfig and its dependencies "
echo ""
echo "========================================================================="
cur_dir=$(pwd)

if [ "$1" != "--help" ]; then

#set mysql root password

	MYSQL_ROOT_PASSWORD="root"
	echo "Please input the root password of mysql:"
	read -p "(Default password: root):" MYSQL_ROOT_PASSWORD
	if [ "$MYSQL_ROOT_PASSWORD" = "" ]; then
		MYSQL_ROOT_PASSWORD="root"
	fi
	echo "==========================="
	echo "MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD"
	echo "==========================="

#set Hostname

	HOSTNAME="server1"
	echo "Please input the Hostname:"
	read -p "(Default Hostname: server1):" HOSTNAME
	if [ "$HOSTNAME" = "" ]; then
		HOSTNAME="server1"
	fi
	echo "==========================="
	echo "HOSTNAME=$HOSTNAME"
	echo "==========================="

#set Fully Qualified Hostname

	HOSTNAMEFQDN="server1.example.com"
	echo "Please input the Full Hostname:"
	read -p "(Default Full Hostname: server1.example.com):" HOSTNAMEFQDN
	if [ "$HOSTNAMEFQDN" = "" ]; then
		HOSTNAMEFQDN="server1"
	fi
	echo "==========================="
	echo "HOSTNAMEFQDN=$HOSTNAMEFQDN"
	echo "==========================="
	
#set Server IP

	serverIP="123.156.78.9"
	echo "Please input the Server IP:"
	read -p "(Default Server IP: 123.456.78.9):" serverIP
	if [ "$serverIP" = "" ]; then
		serverIP="123.456.78.9"
	fi
	echo "==========================="
	echo "serverIP=$serverIP"
	echo "==========================="

#set SSH Port

	sshd_port="22"
	echo "Please input the SSH Port:"
	read -p "(Default SSH Port: 22):" sshd_port
	if [ "$sshd_port" = "" ]; then
		sshd_port="22"
	fi
	echo "==========================="
	echo "sshd_port=$sshd_port"
	echo "==========================="
	
#set Mail Server

	mail_server="Courier"
	echo "Please select Mail Server:"
	read -p "(Default Mail Server: Courier):" mail_server
	if [ "$mail_server" = "" ]; then
		mail_server="22"
	fi
	echo "==========================="
	echo "mail_server=$mail_server"
	echo "==========================="

#set DNS Server
	dns_server="Bind"
	echo "Please select DNS Server:"
	read -p "(Default DNS Server: Bind):" dns_server
	if [ "$dns_server" = "" ]; then
		dns_server="22"
	fi
	echo "==========================="
	echo "dns_server=$dns_server"
	echo "==========================="

#set Quota
	quota="No"
	echo "Please select whether to install Quota or Not:"
	read -p "(Default: No):" quota
	if [ "$quota" = "" ]; then
		quota="No"
	fi
	echo "==========================="
	echo "quota=$quota"
	echo "==========================="

###Functions Begin### 

function basic_server_setup {

#Reconfigure sshd - change port
sed -i 's/^Port [0-9]*/Port '${sshd_port}'/' /etc/ssh/sshd_config
/etc/init.d/ssh reload

#Set hostname and FQDN
sed -i 's/'${serverIP}'.*/'${serverIP}' '${HOSTNAMEFQDN}' '${HOSTNAME}'/' /etc/hosts
echo "$HOSTNAME" > /etc/hostname
/etc/init.d/hostname.sh start >/dev/null 2>&1

#Updates server and install commonly used utilities
aptitude update
aptitude -y safe-upgrade
aptitude -y install vim-nox dnsutils unzip 

} #end function basic_server_setup


function install_DashNTP {
#Reconfigure Dash
dpkg-reconfigure dash
#Use dash as the default system shell (/bin/sh)? <-- No

#Synchronize the System Clock
apt-get -y install ntp ntpdate

}

function install_MYSQLCourier {

#Install Postfix, Courier, Saslauthd, MySQL, phpMyAdmin, rkhunter, binutils
echo "mysql-server-5.1 mysql-server/root_password password $MYSQL_ROOT_PASSWORD" | debconf-set-selections
echo "mysql-server-5.1 mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD" | debconf-set-selections

apt-get -y install postfix postfix-mysql postfix-doc mysql-client mysql-server courier-authdaemon courier-authlib-mysql courier-pop courier-pop-ssl courier-imap courier-imap-ssl libsasl2-2 libsasl2-modules libsasl2-modules-sql sasl2-bin libpam-mysql openssl courier-maildrop getmail4 rkhunter binutils sudo

#Allow MySQL to listen on all interfaces
sed -i 's/bind-address           = 127.0.0.1/#bind-address           = 127.0.0.1/' /etc/mysql/my.cnf
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

}

function install_MYSQLDoveCot {

#Install Postfix, Courier, Saslauthd, MySQL, phpMyAdmin, rkhunter, binutils
echo "mysql-server-5.1 mysql-server/root_password password $MYSQL_ROOT_PASSWORD" | debconf-set-selections
echo "mysql-server-5.1 mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD" | debconf-set-selections

apt-get -y install postfix postfix-mysql postfix-doc mysql-client mysql-server openssl getmail4 rkhunter binutils dovecot-imapd dovecot-pop3d sudo  

#Allow MySQL to listen on all interfaces
sed -i 's/bind-address           = 127.0.0.1/#bind-address           = 127.0.0.1/' /etc/mysql/my.cnf
/etc/init.d/mysql restart

}

function install_Virus {

#Install Amavisd-new, SpamAssassin, And Clamav
apt-get -y install amavisd-new spamassassin clamav clamav-daemon zoo unzip bzip2 arj nomarch lzop cabextract apt-listchanges libnet-ldap-perl libauthen-sasl-perl clamav-docs daemon libio-string-perl libio-socket-ssl-perl libnet-ident-perl zip libnet-dns-perl

}

function install_Apache {

echo "phpmyadmin      phpmyadmin/dbconfig-install     boolean false" | debconf-set-selections
echo "phpmyadmin      phpmyadmin/reconfigure-webserver        multiselect     apache2" | debconf-set-selections

#Install Apache2, PHP5, phpMyAdmin, FCGI, suExec, Pear, And mcrypt
echo -e "\033[35;1m Select Apache 2 for automatic setup. Select No for using database db-config-common! \033[0m"
apt-get -y install apache2 apache2.2-common apache2-doc apache2-mpm-prefork apache2-utils libexpat1 ssl-cert libapache2-mod-php5 php5 php5-common php5-gd php5-mysql php5-imap phpmyadmin php5-cli php5-cgi libapache2-mod-fcgid apache2-suexec php-pear php-auth php5-mcrypt mcrypt php5-imagick imagemagick libapache2-mod-suphp libruby libapache2-mod-ruby

#Web server to reconfigure automatically: <-- apache2
#Configure database for phpmyadmin with dbconfig-common? <-- No

a2enmod suexec rewrite ssl actions include
a2enmod dav_fs dav auth_digest

/etc/init.d/apache2 restart

}

function install_PureFTPD {
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

}

function install_Quota {
#Setting up Quota

apt-get -y install quota quotatool
mount -o remount /
quotacheck -avugm
quotaon -avug

}

function install_Bind {
#Install BIND DNS Server
apt-get -y install bind9 dnsutils

}

function install_Stats {

#Install Vlogger, Webalizer, And AWstats
apt-get -y install vlogger webalizer awstats

sed -i 's/*/10 * * * * www-data [ -x /usr/share/awstats/tools/update.sh ] && /usr/share/awstats/tools/update.sh/#*/10 * * * * www-data [ -x /usr/share/awstats/tools/update.sh ] && /usr/share/awstats/tools/update.sh/' /etc/cron.d/awstats
sed -i 's/10 03 * * * www-data [ -x /usr/share/awstats/tools/buildstatic.sh ] && /usr/share/awstats/tools/buildstatic.sh/#10 03 * * * www-data [ -x /usr/share/awstats/tools/buildstatic.sh ] && /usr/share/awstats/tools/buildstatic.sh/' /etc/cron.d/awstats

}

function install_Jailkit {
#Install Jailkit
apt-get -y install build-essential autoconf automake1.9 libtool flex bison debhelper

cd /tmp
wget http://olivier.sessink.nl/jailkit/jailkit-2.13.tar.gz
tar xvfz jailkit-2.13.tar.gz
cd jailkit-2.13
./debian/rules binary
cd ..
dpkg -i jailkit_2.14-1_*.deb
rm -rf jailkit-2.14*

}

function install_fail2banCourier {
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

}

function install_fail2banDovecot {
#Install fail2ban
apt-get -y install fail2ban

cat > /etc/fail2ban/jail.local <<EOF
[pureftpd]

enabled  = true
port     = ftp
filter   = pureftpd
logpath  = /var/log/syslog
maxretry = 3


[dovecot-pop3imap]

enabled = true
filter = dovecot-pop3imap
action = iptables-multiport[name=dovecot-pop3imap, port="pop3,pop3s,imap,imaps", protocol=tcp]
logpath = /var/log/mail.log
maxretry = 5
EOF

cat > /etc/fail2ban/filter.d/pureftpd.conf <<EOF
[Definition]
failregex = .*pure-ftpd: \(.*@<HOST>\) \[WARNING\] Authentication failed for user.*
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/dovecot-pop3imap.conf <<EOF
[Definition]
failregex = (?: pop3-login|imap-login): .*(?:Authentication failure|Aborted login \(auth failed|Aborted login \(tried to use disabled|Disconnected \(auth failed|Aborted login \(\d+ authentication attempts).*rip=(?P<host>\S*),.*
ignoreregex =
EOF

/etc/init.d/fail2ban restart

}

function install_SquirrelMail {
#Install SquirrelMail
apt-get -y install squirrelmail
ln -s /usr/share/squirrelmail/ /var/www/webmail
squirrelmail-configure

}

function install_ISPConfig {
#Install ISPConfig 3
cd /tmp
wget http://www.ispconfig.org/downloads/ISPConfig-3-stable.tar.gz
tar xfz ISPConfig-3-stable.tar.gz
cd ispconfig3_install/install/
php -q install.php

} 

#Execute functions#
if [ "$1" = "basic" ]; then
    basic_server_setup
    

elif [ "$1" = "ISPConfigBCNQ" ]; then
    install_ISPConfigBCNQ
    echo -e "\033[35;1m Installation of ISPConfig with Bind/Courier No Quota complete! Enjoy! \033[0m"

elif [ "$1" = "ISPConfigBC" ]; then
    install_ISPConfigBC
    echo -e "\033[35;1m Installation of ISPConfig with Bind/Courier-Quota complete! Enjoy! \033[0m"


fi
#End execute functions#