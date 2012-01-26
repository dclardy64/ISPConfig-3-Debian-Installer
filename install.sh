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
echo "ISPConfig 3 Setup Script ,  Written by Drew Clardy with help from other scripts!"
echo "========================================================================="
echo "A tool to auto-install ISPConfig and its dependencies "
echo "Script is using the DotDeb repo for updated packages"
echo "========================================================================="
echo "Press ENTER to continue.."
read DUMMY

if [ "$1" != "--help" ]; then

#set mysql root password

    MYSQL_ROOT_PASSWORD="123456789"
    echo "Please input the root password of mysql:"
    read -p "(Default password: 123456789):" MYSQL_ROOT_PASSWORD
    if [ "$MYSQL_ROOT_PASSWORD" = "" ]; then
        MYSQL_ROOT_PASSWORD="123456789"
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
        HOSTNAMEFQDN="server1.example.com"
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
    
#set Web Server

    web_server="Apache"
	echo "Please select Web Server (Apache or NginX):"
	read -p "(Default Mail Server: NginX):" web_server
    if [ "$web_server" = "" ]; then
    	web_server="NginX"
    fi
    echo "==========================="
    echo "web_server=$web_server"
    echo "==========================="
	
#set Mail Server

    mail_server="Courier"
    echo "Please select Mail Server (Courier or Dovecot):"
    read -p "(Default Mail Server: Courier):" mail_server
    if [ "$mail_server" = "" ]; then
        mail_server="Courier"
    fi
    echo "==========================="
    echo "mail_server=$mail_server"
    echo "==========================="

#set DNS Server
    dns_server="Bind"
    echo "Please select DNS Server (Bind for now):"
    read -p "(Default DNS Server: Bind):" dns_server
    if [ "$dns_server" = "" ]; then
        dns_server="Bind"
    fi
    echo "==========================="
    echo "dns_server=$dns_server"
    echo "==========================="

#set Quota
    quota="Yes"
    echo "Please select whether to install Quota or Not:"
    read -p "(Default: Yes):" quota
    if [ "$quota" = "" ]; then
        quota="Yes"
    fi
    echo "==========================="
    echo "quota=$quota"
    echo "==========================="
    
#set Jailkit
    jailkit="Yes"
    echo "Please select whether to install Jailkit or Not:"
    read -p "(Default: Yes):" jailkit
    if [ "$jailkit" = "" ]; then
        jailkit="Yes"
    fi
    echo "==========================="
    echo "jailkit=$jailkit"
    echo "==========================="


    installchoices="install_$web_server$mail_server$dns_server$quota$jailkit"
    
fi

###Functions Begin### 

install_basic (){

#Reconfigure sshd - change port
sed -i "s/^Port [0-9]*/Port ${sshd_port}/" /etc/ssh/sshd_config
/etc/init.d/ssh reload

#Set hostname and FQDN
sed -i "s/${serverIP}.*/${serverIP} ${HOSTNAMEFQDN} ${HOSTNAME}/" /etc/hosts
echo "$HOSTNAME" > /etc/hostname
/etc/init.d/hostname.sh start >/dev/null 2>&1

#Updates server and install commonly used utilities
cp /etc/apt/sources.list /etc/apt/sources.list.backup
cat > /etc/apt/sources.list <<EOF
deb http://ftp.us.debian.org/debian/ squeeze main contrib non-free
deb http://ftp.us.debian.org/debian/ squeeze-updates main contrib non-free
deb http://security.debian.org/ squeeze/updates main contrib non-free
deb http://packages.dotdeb.org squeeze all
EOF

apt-get update
apt-get -y safe-upgrade
apt-get -y install vim-nox dnsutils unzip 

} #end function install_basic

install_DashNTP (){

echo "dash dash/sh boolean false" | debconf-set-selections
dpkg-reconfigure -f noninteractive dash > /dev/null 2>&1

#Synchronize the System Clock
apt-get -y install ntp ntpdate

} #end function install_DashNTP

install_MYSQLCourier (){

#Install Postfix, Courier, Saslauthd, MySQL, phpMyAdmin, rkhunter, binutils
echo "mysql-server-5.1 mysql-server/root_password password $MYSQL_ROOT_PASSWORD" | debconf-set-selections
echo "mysql-server-5.1 mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD" | debconf-set-selections
echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
echo "postfix postfix/mailname string $HOSTNAMEFQDN" | debconf-set-selections
echo "courier-base courier-base/webadmin-configmode boolean false" | debconf-set-selections
echo "courier-ssl courier-ssl/certnotice note" | debconf-set-selections

apt-get -y install postfix postfix-mysql postfix-doc mysql-client mysql-server courier-authdaemon courier-authlib-mysql courier-pop courier-pop-ssl courier-imap courier-imap-ssl libsasl2-2 libsasl2-modules libsasl2-modules-sql sasl2-bin libpam-mysql openssl courier-maildrop getmail4 rkhunter binutils sudo

#Allow MySQL to listen on all interfaces
sed -i 's/bind-address           = 127.0.0.1/#bind-address           = 127.0.0.1/' /etc/mysql/my.cnf
/etc/init.d/mysql restart

#Delete and Reconfigure SSL Certificates
cd /etc/courier
rm -f /etc/courier/imapd.pem
rm -f /etc/courier/pop3d.pem
sed -i "s/CN=localhost/CN=${HOSTNAMEFQDN}/" /etc/courier/imapd.cnf
sed -i "s/CN=localhost/CN=${HOSTNAMEFQDN}/" /etc/courier/pop3d.cnf
mkimapdcert
mkpop3dcert
/etc/init.d/courier-imap-ssl restart
/etc/init.d/courier-pop-ssl restart

}

install_MYSQLDovecot (){

#Install Postfix, Courier, Saslauthd, MySQL, phpMyAdmin, rkhunter, binutils
echo "mysql-server-5.1 mysql-server/root_password password $MYSQL_ROOT_PASSWORD" | debconf-set-selections
echo "mysql-server-5.1 mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD" | debconf-set-selections
echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
echo "postfix postfix/mailname string $HOSTNAMEFQDN" | debconf-set-selections

apt-get -y install postfix postfix-mysql postfix-doc mysql-client mysql-server openssl getmail4 rkhunter binutils dovecot-imapd dovecot-pop3d sudo  

#Allow MySQL to listen on all interfaces
sed -i 's/bind-address           = 127.0.0.1/#bind-address           = 127.0.0.1/' /etc/mysql/my.cnf
/etc/init.d/mysql restart

}

install_Virus (){

#Install Amavisd-new, SpamAssassin, And Clamav
apt-get -y install amavisd-new spamassassin clamav clamav-daemon zoo unzip bzip2 arj nomarch lzop cabextract apt-listchanges libnet-ldap-perl libauthen-sasl-perl clamav-docs daemon libio-string-perl libio-socket-ssl-perl libnet-ident-perl zip libnet-dns-perl

}

install_Apache (){

#Install Apache2, PHP5, phpMyAdmin, FCGI, suExec, Pear, And mcrypt
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
#DISABLED DUE TO A BUG IN DBCONFIG - echo "phpmyadmin phpmyadmin/dbconfig-install boolean false" | debconf-set-selections
echo "dbconfig-common dbconfig-common/dbconfig-install boolean false" | debconf-set-selections

apt-get -y install apache2 apache2.2-common apache2-doc apache2-mpm-prefork apache2-utils libexpat1 ssl-cert libapache2-mod-php5 php5 php5-common php5-gd php5-mysql php5-imap phpmyadmin php5-cli php5-cgi libapache2-mod-fcgid apache2-suexec php-pear php-auth php5-mcrypt mcrypt php5-imagick imagemagick libapache2-mod-suphp libruby libapache2-mod-ruby

#Web server to reconfigure automatically: <-- apache2
#Configure database for phpmyadmin with dbconfig-common? <-- No

a2enmod suexec rewrite ssl actions include
a2enmod dav_fs dav auth_digest

/etc/init.d/apache2 restart

}

install_NginX (){

#Install NginX, PHP5, phpMyAdmin, FCGI, suExec, Pear, And mcrypt
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
# - DISABLED DUE TO A BUG IN DBCONFIG - echo "phpmyadmin phpmyadmin/dbconfig-install boolean false" | debconf-set-selections
echo "dbconfig-common dbconfig-common/dbconfig-install boolean false" | debconf-set-selections
apt-get -y install nginx
/etc/init.d/apache2 stop
insserv -r apache2
/etc/init.d/nginx start

apt-get -y install php5-fpm
apt-get -y install php5-mysql php5-curl php5-gd php5-intl php-pear php5-imagick php5-imap php5-mcrypt php5-memcache php5-ming php5-ps php5-pspell php5-recode php5-snmp php5-sqlite php5-tidy php5-xmlrpc php5-xsl
apt-get -y install php-apc
apt-get -y install fcgiwrap
apt-get -y install phpmyadmin

/etc/init.d/php5-fpm restart

}

install_PureFTPD (){
#Install PureFTPd
apt-get -y install pure-ftpd-common pure-ftpd-mysql

#Setting up Pure-Ftpd

sed -i 's/VIRTUALCHROOT=false/VIRTUALCHROOT=true/' /etc/default/pure-ftpd-common
sed -i 's/ftp    stream  tcp     nowait  root    /usr/sbin/tcpd /usr/sbin/pure-ftpd-wrapper/#ftp    stream  tcp     nowait  root    /usr/sbin/tcpd /usr/sbin/pure-ftpd-wrapper/' /etc/inetd.conf
/etc/init.d/openbsd-inetd restart
echo 1 > /etc/pure-ftpd/conf/TLS
mkdir -p /etc/ssl/private/
echo "==========================================================================================="
echo "The following questions can be left as default (just press enter), but when"
echo "asked for 'Common Name', enter your FQDN hostname ($HOSTNAMEFQDN)."
echo "==========================================================================================="
echo "Press ENTER to continue.."
read DUMMY

openssl req -x509 -nodes -days 7300 -newkey rsa:2048 -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem
chmod 600 /etc/ssl/private/pure-ftpd.pem
/etc/init.d/pure-ftpd-mysql restart

}

install_Quota (){
#Setting up Quota

apt-get -y install quota quotatool
mount -o remount /
quotacheck -avugm
quotaon -avug

}

install_Bind (){
#Install BIND DNS Server
apt-get -y install bind9 dnsutils

}

install_Stats (){

#Install Vlogger, Webalizer, And AWstats
apt-get -y install vlogger webalizer awstats

sed -i "s/*/10 * * * * www-data/#*/10 * * * * www-data/" /etc/cron.d/awstats
sed -i "s/10 03 * * * www-data/#10 03 * * * www-data/" /etc/cron.d/awstats

}

install_Jailkit (){
#Install Jailkit
apt-get -y install build-essential autoconf automake1.9 libtool flex bison debhelper

cd /tmp
wget http://olivier.sessink.nl/jailkit/jailkit-2.14.tar.gz
tar xvfz jailkit-2.14.tar.gz
cd jailkit-2.14
./debian/rules binary
cd ..
dpkg -i jailkit_2.14-1_*.deb
rm -rf jailkit-2.14*

}

install_fail2banCourier (){
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

install_fail2banDovecot (){
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

install_SquirrelMail (){

echo "\033[35;1m When prompted, type D! Then type the mailserver you choose ($mail_server), and hit enter. Type S, Hit Enter. Type Q, Hit Enter.  \033[0m"
echo "==========================================================================================="
echo "When prompted, type D! Then type the mailserver you choose ($mail_server),"
echo "and hit enter. Type S, Hit Enter. Type Q, Hit Enter."
echo "==========================================================================================="
echo "Press ENTER to continue.."
read DUMMY
#Install SquirrelMail
apt-get -y install squirrelmail
ln -s /usr/share/squirrelmail/ /var/www/webmail
squirrelmail-configure

}

install_ISPConfig (){
#Install ISPConfig 3
cd /tmp
wget http://www.ispconfig.org/downloads/ISPConfig-3-stable.tar.gz
tar xfz ISPConfig-3-stable.tar.gz
cd ispconfig3_install/install/
php -q install.php

} 

#Execute functions#
if [ "$installchoices" = "install_ApacheCourierBindNoNo" ]; then
    install_basic
    install_DashNTP
    install_MYSQLCourier
    install_Virus
    install_Apache
    install_PureFTPD
    install_Bind
    install_Stats
    install_fail2banCourier
    install_SquirrelMail
    install_ISPConfig

elif [ "$installchoices" = "install_ApacheCourierBindYesNo" ]; then
    install_basic
    install_DashNTP
    install_MYSQLCourier
    install_Virus
    install_Apache
    install_PureFTPD
    install_Quota
    install_Bind
    install_Stats
    install_fail2banCourier
    install_SquirrelMail
    install_ISPConfig

elif [ "$installchoices" = "install_ApacheCourierBindYesYes" ]; then
    install_basic
    install_DashNTP
    install_MYSQLCourier
    install_Virus
    install_Apache
    install_PureFTPD
    install_Quota
    install_Bind
    install_Stats
    install_Jailkit
    install_fail2banCourier
    install_SquirrelMail
    install_ISPConfig
    
elif [ "$installchoices" = "install_ApacheCourierBindNoYes" ]; then
    install_basic
    install_DashNTP
    install_MYSQLCourier
    install_Virus
    install_Apache
    install_PureFTPD
    install_Bind
    install_Stats
    install_Jailkit
    install_fail2banCourier
    install_SquirrelMail
    install_ISPConfig
    
elif [ "$installchoices" = "install_ApacheDovecotBindNoNo" ]; then
    install_basic
    install_DashNTP
    install_MYSQLDovecot
    install_Virus
    install_Apache
    install_PureFTPD
    install_Bind
    install_Stats
    install_fail2banDovecot
    install_SquirrelMail
    install_ISPConfig

elif [ "$installchoices" = "install_ApacheDovecotBindYesNo" ]; then
    install_basic
    install_DashNTP
    install_MYSQLDovecot
    install_Virus
    install_Apache
    install_PureFTPD
    install_Quota
    install_Bind
    install_Stats
    install_fail2banDovecot
    install_SquirrelMail
    install_ISPConfig

elif [ "$installchoices" = "install_ApacheDovecotBindYesYes" ]; then
    install_basic
    install_DashNTP
    install_MYSQLDovecot
    install_Virus
    install_Apache
    install_PureFTPD
    install_Quota
    install_Bind
    install_Stats
    install_Jailkit
    install_fail2banDovecot
    install_SquirrelMail
    install_ISPConfig
    
elif [ "$installchoices" = "install_ApacheDovecotBindNoYes" ]; then
    install_basic
    install_DashNTP
    install_MYSQLDovecot
    install_Virus
    install_Apache
    install_PureFTPD
    install_Bind
    install_Stats
    install_Jailkit
    install_fail2banDovecot
    install_SquirrelMail
    install_ISPConfig

elif [ "$installchoices" = "install_NginXCourierBindNoNo" ]; then
    install_basic
    install_DashNTP
    install_MYSQLCourier
    install_Virus
    install_NginX
    install_PureFTPD
    install_Bind
    install_Stats
    install_fail2banCourier
    install_SquirrelMail
    install_ISPConfig

elif [ "$installchoices" = "install_NginXCourierBindYesNo" ]; then
    install_basic
    install_DashNTP
    install_MYSQLCourier
    install_Virus
    install_NginX
    install_PureFTPD
    install_Quota
    install_Bind
    install_Stats
    install_fail2banCourier
    install_SquirrelMail
    install_ISPConfig

elif [ "$installchoices" = "install_NginXCourierBindYesYes" ]; then
    install_basic
    install_DashNTP
    install_MYSQLCourier
    install_Virus
    install_NginX
    install_PureFTPD
    install_Quota
    install_Bind
    install_Stats
    install_Jailkit
    install_fail2banCourier
    install_SquirrelMail
    install_ISPConfig
    
elif [ "$installchoices" = "install_NginXCourierBindNoYes" ]; then
    install_basic
    install_DashNTP
    install_MYSQLCourier
    install_Virus
    install_NginX
    install_PureFTPD
    install_Bind
    install_Stats
    install_Jailkit
    install_fail2banCourier
    install_SquirrelMail
    install_ISPConfig
    
elif [ "$installchoices" = "install_NginXDovecotBindNoNo" ]; then
    install_basic
    install_DashNTP
    install_MYSQLDovecot
    install_Virus
    install_NginX
    install_PureFTPD
    install_Bind
    install_Stats
    install_fail2banDovecot
    install_SquirrelMail
    install_ISPConfig

elif [ "$installchoices" = "install_NginXDovecotBindYesNo" ]; then
    install_basic
    install_DashNTP
    install_MYSQLDovecot
    install_Virus
    install_NginX
    install_PureFTPD
    install_Quota
    install_Bind
    install_Stats
    install_fail2banDovecot
    install_SquirrelMail
    install_ISPConfig

elif [ "$installchoices" = "install_NginXDovecotBindYesYes" ]; then
    install_basic
    install_DashNTP
    install_MYSQLDovecot
    install_Virus
    install_NginX
    install_PureFTPD
    install_Quota
    install_Bind
    install_Stats
    install_Jailkit
    install_fail2banDovecot
    install_SquirrelMail
    install_ISPConfig
    
elif [ "$installchoices" = "install_NginXDovecotBindNoYes" ]; then
    install_basic
    install_DashNTP
    install_MYSQLDovecot
    install_Virus
    install_NginX
    install_PureFTPD
    install_Bind
    install_Stats
    install_Jailkit
    install_fail2banDovecot
    install_SquirrelMail
    install_ISPConfig
fi
#End execute functions#