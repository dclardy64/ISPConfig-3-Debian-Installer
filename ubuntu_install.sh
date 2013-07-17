#!/bin/bash

###############################################################################################
# Complete ISPConfig setup script for Ubuntu 13.04.								 			  #
# Drew Clardy																				  #
# http://drewclardy.com							                                              #
###############################################################################################

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use the root user to install the software."
    exit 1
fi

back_title="ISPConfig 3 System Installer"

questions (){
  while [ "x$serverIP" == "x" ]
  do
        serverIP=$(whiptail --title "Server IP" --backtitle "$back_title" --inputbox "Please specify a Server IP" --nocancel 10 50 3>&1 1>&2 2>&3)
  done
  while [ "x$HOSTNAMESHORT" == "x" ]
  do
        HOSTNAMESHORT=$(whiptail --title "Hostname" --backtitle "$back_title" --inputbox "Please specify a Hostname" --nocancel 10 50 3>&1 1>&2 2>&3)
  done
  while [ "x$HOSTNAMEFQDN" == "x" ]
  do
        HOSTNAMEFQDN=$(whiptail --title "Fully Qualified Hostname" --backtitle "$back_title" --inputbox "Please specify a Fully Qualified Hostname" --nocancel 10 50 3>&1 1>&2 2>&3)
  done
  while [ "x$web_server" == "x" ]
  do
    web_server=$(whiptail --title "Web Server" --backtitle "$back_title" --nocancel --radiolist "Select Web Server Software" 10 50 2 "Apache" "(default)" ON "NginX" "" OFF 3>&1 1>&2 2>&3)
  done
  while [ "x$mail_server" == "x" ]
  do
    mail_server=$(whiptail --title "Mail Server" --backtitle "$back_title" --nocancel --radiolist "Select Mail Server Software" 10 50 2 "Dovecot" "(default)" ON "Courier" "" OFF 3>&1 1>&2 2>&3)
  done
  while [ "x$mysql_pass" == "x" ]
  do
        mysql_pass=$(whiptail --title "MySQL Root Password" --backtitle "$back_title" --inputbox "Please specify a MySQL Root Password" --nocancel 10 50 3>&1 1>&2 2>&3)
  done
  if (whiptail --title "Install Quota" --backtitle "$back_title" --yesno "Setup User Quotas?" 10 50) then
    quota=Yes
  else
    quota=No
  fi
  if (whiptail --title "Install Mailman" --backtitle "$back_title" --yesno "Setup Mailman?" 10 50) then
    mailman=Yes
  else
    mailman=No
  fi
  if (whiptail --title "Install Jailkit" --backtitle "$back_title" --yesno "Setup User Jailkits?" 10 50) then
    jailkit=Yes
  else
    jailkit=No
  fi

}

ubuntu_install_basic (){

#Set hostname and FQDN
cp /etc/hosts /etc/hosts.backup
sed -i "s/${serverIP}.*/${serverIP} ${HOSTNAMEFQDN} ${HOSTNAMESHORT}/" /etc/hosts
echo "$HOSTNAMESHORT" > /etc/hostname
/etc/init.d/hostname.sh start >/dev/null 2>&1

#Updates server and install commonly used utilities
cp /etc/apt/sources.list /etc/apt/sources.list.backup
cat > /etc/apt/sources.list <<EOF
# See http://help.ubuntu.com/community/UpgradeNotes for how to upgrade to
# newer versions of the distribution.
deb http://de.archive.ubuntu.com/ubuntu/ raring main restricted
deb-src http://de.archive.ubuntu.com/ubuntu/ raring main restricted

## Major bug fix updates produced after the final release of the
## distribution.
deb http://de.archive.ubuntu.com/ubuntu/ raring-updates main restricted
deb-src http://de.archive.ubuntu.com/ubuntu/ raring-updates main restricted

## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
## team. Also, please note that software in universe WILL NOT receive any
## review or updates from the Ubuntu security team.
deb http://de.archive.ubuntu.com/ubuntu/ raring universe
deb-src http://de.archive.ubuntu.com/ubuntu/ raring universe
deb http://de.archive.ubuntu.com/ubuntu/ raring-updates universe
deb-src http://de.archive.ubuntu.com/ubuntu/ raring-updates universe

## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
## team, and may not be under a free licence. Please satisfy yourself as to
## your rights to use the software. Also, please note that software in
## multiverse WILL NOT receive any review or updates from the Ubuntu
## security team.
deb http://de.archive.ubuntu.com/ubuntu/ raring multiverse
deb-src http://de.archive.ubuntu.com/ubuntu/ raring multiverse
deb http://de.archive.ubuntu.com/ubuntu/ raring-updates multiverse
deb-src http://de.archive.ubuntu.com/ubuntu/ raring-updates multiverse

## N.B. software from this repository may not have been tested as
## extensively as that contained in the main release, although it includes
## newer versions of some applications which may provide useful features.
## Also, please note that software in backports WILL NOT receive any review
## or updates from the Ubuntu security team.
deb http://de.archive.ubuntu.com/ubuntu/ raring-backports main restricted universe multiverse
deb-src http://de.archive.ubuntu.com/ubuntu/ raring-backports main restricted universe multiverse

deb http://security.ubuntu.com/ubuntu raring-security main restricted
deb-src http://security.ubuntu.com/ubuntu raring-security main restricted
deb http://security.ubuntu.com/ubuntu raring-security universe
deb-src http://security.ubuntu.com/ubuntu raring-security universe
deb http://security.ubuntu.com/ubuntu raring-security multiverse
deb-src http://security.ubuntu.com/ubuntu raring-security multiverse

## Uncomment the following two lines to add software from Canonical's
## 'partner' repository.
## This software is not part of Ubuntu, but is offered by Canonical and the
## respective vendors as a service to Ubuntu users.
# deb http://archive.canonical.com/ubuntu raring partner
# deb-src http://archive.canonical.com/ubuntu raring partner

## Uncomment the following two lines to add software from Ubuntu's
## 'extras' repository.
## This software is not part of Ubuntu, but is offered by third-party
## developers who want to ship their latest software.
# deb http://extras.ubuntu.com/ubuntu raring main
# deb-src http://extras.ubuntu.com/ubuntu raring main
EOF

apt-get update
apt-get -y upgrade
apt-get -y install vim-nox dnsutils unzip nano

} #end function ubuntu_install_basic

ubuntu_install_DisableAppArmor (){

/etc/init.d/apparmor stop
update-rc.d -f apparmor remove
apt-get -y remove apparmor apparmor-utils

} #end function ubuntu_install_DisableAppArmor

ubuntu_install_DashNTP (){

echo "dash dash/sh boolean false" | debconf-set-selections
dpkg-reconfigure -f noninteractive dash > /dev/null 2>&1

#Synchronize the System Clock
apt-get -y install ntp ntpdate

} #end function ubuntu_install_DashNTP

ubuntu_install_MYSQLCourier (){

#Install Postfix, Courier, Saslauthd, MySQL, phpMyAdmin, rkhunter, binutils
echo "mysql-server-5.5 mysql-server/root_password password $mysql_pass" | debconf-set-selections
echo "mysql-server-5.5 mysql-server/root_password_again password $mysql_pass" | debconf-set-selections
echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
echo "postfix postfix/mailname string $HOSTNAMEFQDN" | debconf-set-selections
echo "courier-base courier-base/webadmin-configmode boolean false" | debconf-set-selections
echo "courier-ssl courier-ssl/certnotice note" | debconf-set-selections

apt-get -y install postfix postfix-mysql postfix-doc mysql-client mysql-server courier-authdaemon courier-authlib-mysql courier-pop courier-pop-ssl courier-imap courier-imap-ssl libsasl2-2 libsasl2-modules libsasl2-modules-sql sasl2-bin libpam-mysql openssl getmail4 rkhunter binutils maildrop
    
#Allow MySQL to listen on all interfaces
cp /etc/mysql/my.cnf /etc/mysql/my.cnf.backup
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

ubuntu_install_MYSQLDovecot (){

#Install Postfix, Dovecot, Saslauthd, MySQL, phpMyAdmin, rkhunter, binutils
echo "mysql-server-5.5 mysql-server/root_password password $mysql_pass" | debconf-set-selections
echo "mysql-server-5.5 mysql-server/root_password_again password $mysql_pass" | debconf-set-selections
echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
echo "postfix postfix/mailname string $HOSTNAMEFQDN" | debconf-set-selections

apt-get -y install postfix postfix-mysql postfix-doc mysql-client mysql-server openssl getmail4 rkhunter binutils dovecot-imapd dovecot-pop3d dovecot-mysql dovecot-sieve sudo

#Uncommenting some Postfix configuration files
cp /etc/postfix/master.cf /etc/postfix/master.cf.backup
sed -i 's|#submission inet n       -       -       -       -       smtpd|submission inet n       -       -       -       -       smtpd|' /etc/postfix/master.cf
sed -i 's|#  -o syslog_name=postfix/submission|  -o syslog_name=postfix/submission|' /etc/postfix/master.cf
sed -i 's|#  -o smtpd_tls_security_level=encrypt|  -o smtpd_tls_security_level=encrypt|' /etc/postfix/master.cf
sed -i 's|#  -o smtpd_sasl_auth_enable=yes|  -o smtpd_sasl_auth_enable=yes|' /etc/postfix/master.cf
sed -i 's|#  -o smtpd_client_restrictions=permit_sasl_authenticated,reject|  -o smtpd_client_restrictions=permit_sasl_authenticated,reject|' /etc/postfix/master.cf
sed -i 's|#  -o smtpd_sasl_auth_enable=yes|  -o smtpd_sasl_auth_enable=yes|' /etc/postfix/master.cf
sed -i 's|#  -o smtpd_sasl_auth_enable=yes|  -o smtpd_sasl_auth_enable=yes|' /etc/postfix/master.cf
sed -i 's|#  -o smtpd_sasl_auth_enable=yes|  -o smtpd_sasl_auth_enable=yes|' /etc/postfix/master.cf
sed -i 's|#smtps     inet  n       -       -       -       -       smtpd|smtps     inet  n       -       -       -       -       smtpd|' /etc/postfix/master.cf
sed -i 's|#  -o syslog_name=postfix/smtps|  -o syslog_name=postfix/smtps|' /etc/postfix/master.cf
sed -i 's|#  -o smtpd_tls_wrappermode=yes|  -o smtpd_tls_wrappermode=yes|' /etc/postfix/master.cf

/etc/init.d/postfix restart

#Allow MySQL to listen on all interfaces
cp /etc/mysql/my.cnf /etc/mysql/my.cnf.backup
sed -i 's/bind-address           = 127.0.0.1/#bind-address           = 127.0.0.1/' /etc/mysql/my.cnf

/etc/init.d/mysql restart

}

ubuntu_install_Virus (){

#Install Amavisd-new, SpamAssassin, And Clamav
apt-get -y install amavisd-new spamassassin clamav clamav-daemon zoo unzip bzip2 arj nomarch lzop cabextract apt-listchanges libnet-ldap-perl libauthen-sasl-perl clamav-docs daemon libio-string-perl libio-socket-ssl-perl libnet-ident-perl zip libnet-dns-perl

#Stop SpamAssassin. ISPConfig 3 uses amavisd
/etc/init.d/spamassassin stop
update-rc.d -f spamassassin remove

}

ubuntu_install_Apache (){

#Install Apache2, PHP5, phpMyAdmin, FCGI, suExec, Pear, And mcrypt

echo 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2' | debconf-set-selections
echo 'phpmyadmin      phpmyadmin/dbconfig-install     boolean false' | debconf-set-selections

apt-get -y install apache2 apache2.2-common apache2-doc apache2-mpm-prefork apache2-utils libexpat1 ssl-cert libapache2-mod-php5 php5 php5-common php5-gd php5-mysql php5-imap phpmyadmin php5-cli php5-cgi libapache2-mod-fcgid apache2-suexec php-pear php-auth php5-mcrypt mcrypt php5-imagick imagemagick libapache2-mod-suphp libruby libapache2-mod-ruby libapache2-mod-python php5-curl php5-intl php5-memcache php5-memcached php5-ming php5-ps php5-pspell php5-recode php5-snmp php5-sqlite php5-tidy php5-xmlrpc php5-xsl memcached

a2enmod suexec rewrite ssl actions include
a2enmod dav_fs dav auth_digest

cp /etc/apache2/mods-available/suphp.conf /etc/apache2/mods-available/suphp.conf.backup
cat > /etc/apache2/mods-available/suphp.conf <<EOF
<IfModule mod_suphp.c>
    #<FilesMatch "\.ph(p3?|tml)$">
    #    SetHandler application/x-httpd-suphp
    #</FilesMatch>
        AddType application/x-httpd-suphp .php .php3 .php4 .php5 .phtml
        suPHP_AddHandler application/x-httpd-suphp

    <Directory />
        suPHP_Engine on
    </Directory>

    # By default, disable suPHP for debian packaged web applications as files
    # are owned by root and cannot be executed by suPHP because of min_uid.
    <Directory /usr/share>
        suPHP_Engine off
    </Directory>

# # Use a specific php config file (a dir which contains a php.ini file)
#       suPHP_ConfigPath /etc/php5/cgi/suphp/
# # Tells mod_suphp NOT to handle requests with the type <mime-type>.
#       suPHP_RemoveHandler <mime-type>
</IfModule>
EOF



sed -i "s/x-ruby                             rb/x-ruby                            rb/#x-ruby                             rb/x-ruby                            rb/" /etc/mime.types

#Install X-Cache
apt-get -y install php5-xcache

/etc/init.d/apache2 restart

}

ubuntu_install_NginX (){

#Install NginX, PHP5, phpMyAdmin, FCGI, suExec, Pear, And mcrypt

echo 'phpmyadmin      phpmyadmin/reconfigure-webserver        multiselect' | debconf-set-selections
echo 'phpmyadmin      phpmyadmin/dbconfig-install     boolean false' | debconf-set-selections

apt-get -y install nginx

/etc/init.d/apache2 stop
update-rc.d -f apache2 remove

/etc/init.d/nginx start

apt-get -y install php5-fpm php5-mysql php5-curl php5-gd php5-intl php-pear php5-imagick php5-imap php5-mcrypt php5-memcache php5-ming php5-ps php5-pspell php5-recode php5-snmp php5-sqlite php5-tidy php5-xmlrpc php5-xsl
apt-get -y install php-apc
#PHP Configuration Stuff Goes Here
/etc/init.d/php5-fpm reload
apt-get -y install fcgiwrap

apt-get -y install phpmyadmin

#Remove the Apache2 Stuff for NginX
/etc/init.d/apache2 stop
insserv -r apache2
/etc/init.d/nginx start

/etc/init.d/php5-fpm restart

}

ubuntu_install_Mailman (){

echo "================================================================================================"
echo "You will be prompted for some information during the install."
echo "Select the languages you want to support and hit OK when told about the missing site list"
echo "You will also be asked for the email address of person running the list & password for the list."
echo "Please enter them where needed."
echo "================================================================================================"
echo "Press ENTER to continue.."
read DUMMY

#Install Mailman
apt-get -y install mailman
newlist mailman

mv /etc/aliases /etc/aliases.backup

cat > /etc/aliases.mailman <<EOF
mailman:              "|/var/lib/mailman/mail/mailman post mailman"
mailman-admin:        "|/var/lib/mailman/mail/mailman admin mailman"
mailman-bounces:      "|/var/lib/mailman/mail/mailman bounces mailman"
mailman-confirm:      "|/var/lib/mailman/mail/mailman confirm mailman"
mailman-join:         "|/var/lib/mailman/mail/mailman join mailman"
mailman-leave:        "|/var/lib/mailman/mail/mailman leave mailman"
mailman-owner:        "|/var/lib/mailman/mail/mailman owner mailman"
mailman-request:      "|/var/lib/mailman/mail/mailman request mailman"
mailman-subscribe:    "|/var/lib/mailman/mail/mailman subscribe mailman"
mailman-unsubscribe:  "|/var/lib/mailman/mail/mailman unsubscribe mailman"
EOF

cat /etc/aliases.backup /etc/aliases.mailman > /etc/aliases
newaliases
/etc/init.d/postfix restart
    if [ $web_server == "Apache" ]; then
        ln -s /etc/mailman/apache.conf /etc/apache2/conf.d/mailman.conf
        /etc/init.d/apache2 restart
    fi
/etc/init.d/mailman start

}

ubuntu_install_PureFTPD (){
#Install PureFTPd
apt-get -y install pure-ftpd-common pure-ftpd-mysql

#Setting up Pure-Ftpd

sed -i 's/VIRTUALCHROOT=false/VIRTUALCHROOT=true/' /etc/default/pure-ftpd-common
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

ubuntu_install_Quota (){

#Editing FStab
cp /etc/fstab /etc/fstab.backup
sed -i "s/errors=remount-ro/errors=remount-ro,usrjquota=quota.user,grpjquota=quota.group,jqfmt=vfsv0/" /etc/fstab

#Setting up Quota

apt-get -y install quota quotatool
mount -o remount /
quotacheck -avugm
quotaon -avug

}

ubuntu_install_Bind (){
#Install BIND DNS Server
apt-get -y install bind9 dnsutils

}

ubuntu_install_Stats (){

#Install Vlogger, Webalizer, And AWstats
apt-get -y install vlogger webalizer awstats geoip-database libclass-dbi-mysql-perl

sed -i "s/*/10 * * * * www-data/#*/10 * * * * www-data/" /etc/cron.d/awstats
sed -i "s/10 03 * * * www-data/#10 03 * * * www-data/" /etc/cron.d/awstats

}

ubuntu_install_Jailkit (){
#Install Jailkit
apt-get -y install build-essential autoconf automake1.9 libtool flex bison debhelper binutils-gold

cd /tmp
wget http://olivier.sessink.nl/jailkit/jailkit-2.16.tar.gz
tar xvfz jailkit-2.16.tar.gz
cd jailkit-2.16
./debian/rules binary
cd ..
dpkg -i jailkit_2.16-1_*.deb
rm -rf jailkit-2.16*

}

ubuntu_install_Fail2BanCourier (){
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
maxretry = 5
EOF
}

ubuntu_install_Fail2BanDovecot() {
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

[sasl]
enabled  = true
port     = smtp
filter   = sasl
logpath  = /var/log/mail.log
maxretry = 3
EOF

}

ubuntu_install_Fail2BanRulesCourier() {

cat > /etc/fail2ban/filter.d/pureftpd.conf <<EOF
[Definition]
failregex = .*pure-ftpd: \(.*@<HOST>\) \[WARNING\] Authentication failed for user.*
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/courierpop3.conf <<EOF
[Definition]
failregex = pop3d: LOGIN FAILED.*ip=\[.*:<HOST>\]
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/courierpop3s.conf <<EOF
[Definition]
failregex = pop3d-ssl: LOGIN FAILED.*ip=\[.*:<HOST>\]
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/courierimap.conf <<EOF
[Definition]
failregex = imapd: LOGIN FAILED.*ip=\[.*:<HOST>\]
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/courierimaps.conf <<EOF
[Definition]
failregex = imapd-ssl: LOGIN FAILED.*ip=\[.*:<HOST>\]
ignoreregex =
EOF

/etc/init.d/fail2ban restart

}

ubuntu_install_Fail2BanRulesDovecot() {

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

ubuntu_install_SquirrelMail (){

echo "==========================================================================================="
echo "When prompted, type D! Then type the mailserver you choose ($mail_server),"
echo "and hit enter. Type S, Hit Enter. Type Q, Hit Enter."
echo "==========================================================================================="
echo "Press ENTER to continue.."
read DUMMY
#Install SquirrelMail
apt-get -y install squirrelmail
    if [ $web_server == "Apache" ]; then
        ln -s /usr/share/squirrelmail/ /var/www/webmail
    fi

squirrelmail-configure

}

install_ISPConfig (){
#Install ISPConfig 3
cd /tmp
wget http://www.ispconfig.org/downloads/ISPConfig-3-stable.tar.gz
tar xfz ISPConfig-3-stable.tar.gz
cd /tmp/ispconfig3_install/install/
php -q install.php

} 

#Execute functions#
if [ -f /etc/debian_version ]; then 
    questions
    ubuntu_install_basic
    ubuntu_install_DisableAppArmor
    ubuntu_install_DashNTP
    if [ $mail_server == "Courier" ]; then
        ubuntu_install_MYSQLCourier
    fi
    if [ $mail_server == "Dovecot" ]; then
        ubuntu_install_MYSQLDovecot
    fi
    ubuntu_install_Virus
    if [ $web_server == "Apache" ]; then
        ubuntu_install_Apache
    fi
    if [ $web_server == "NginX" ]; then
        ubuntu_install_NginX
    fi
    if [ $mailman == "Yes" ]; then
        ubuntu_install_Mailman
    fi
    ubuntu_install_PureFTPD
    if [ $quota == "Yes" ]; then
        ubuntu_install_Quota
    fi
    ubuntu_install_Bind
    ubuntu_install_Stats
    if [ $jailkit == "Yes" ]; then
        ubuntu_install_Jailkit
    fi
    if [ $mail_server == "Courier" ]; then
        ubuntu_install_Fail2BanCourier
        ubuntu_install_Fail2BanRulesCourier
    fi
    if [ $mail_server == "Dovecot" ]; then
        ubuntu_install_Fail2BanDovecot
        ubuntu_install_Fail2BanRulesDovecot
    fi
    ubuntu_install_SquirrelMail
    install_ISPConfig
else echo "Unsupported Linux Distribution."
fi      

#End execute functions#
