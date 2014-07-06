#!/bin/bash

###############################################################################################
# Complete ISPConfig setup script for Debian/Ubuntu Systems         						  #
# Drew Clardy												                                  # 
# http://drewclardy.com				                                                          #
# http://github.com/dclardy64/ISPConfig-3-Debian-Install                                      #
###############################################################################################

back_title="ISPConfig 3 System Installer"

ubuntu.install_Repos (){

#Updates server and install commonly used utilities
cp /etc/apt/sources.list /etc/apt/sources.list.backup
cat > /etc/apt/sources.list <<EOF
deb mirror://mirrors.ubuntu.com/mirrors.txt trusty main restricted
deb-src mirror://mirrors.ubuntu.com/mirrors.txt trusty-updates main restricted

deb mirror://mirrors.ubuntu.com/mirrors.txt trusty universe
deb-src mirror://mirrors.ubuntu.com/mirrors.txt trusty universe

deb mirror://mirrors.ubuntu.com/mirrors.txt trusty-updates universe
deb-src mirror://mirrors.ubuntu.com/mirrors.txt trusty-updates universe

deb mirror://mirrors.ubuntu.com/mirrors.txt trusty multiverse
deb-src mirror://mirrors.ubuntu.com/mirrors.txt trusty multiverse

deb mirror://mirrors.ubuntu.com/mirrors.txt trusty-updates multiverse
deb-src mirror://mirrors.ubuntu.com/mirrors.txt trusty-updates multiverse

deb mirror://mirrors.ubuntu.com/mirrors.txt trusty-backports main restricted universe multiverse
deb-src mirror://mirrors.ubuntu.com/mirrors.txt trusty-backports main restricted universe multiverse

deb mirror://mirrors.ubuntu.com/mirrors.txt trusty-security main restricted
deb-src mirror://mirrors.ubuntu.com/mirrors.txt trusty-security main restricted

deb mirror://mirrors.ubuntu.com/mirrors.txt trusty-security universe
deb-src mirror://mirrors.ubuntu.com/mirrors.txt trusty-security universe
EOF

} #end function ubuntu.install_Repos

ubuntu.install_DisableAppArmor (){

/etc/init.d/apparmor stop
update-rc.d -f apparmor remove
apt-get -y remove apparmor apparmor-utils

} #end function ubuntu.install_DisableAppArmor

ubuntu.install_MySQL (){

#Install MySQL
echo "mysql-server-5.6 mysql-server/root_password password $mysql_pass" | debconf-set-selections
echo "mysql-server-5.6 mysql-server/root_password_again password $mysql_pass" | debconf-set-selections

apt-get -y install mysql-client mysql-server
apt-get -y install php5-cli php5-mysql php5-mcrypt mcrypt
    
#Allow MySQL to listen on all interfaces
cp /etc/mysql/my.cnf /etc/mysql/my.cnf.backup
sed -i 's/bind-address/#bind-address' /etc/mysql/my.cnf

service mysql restart

} #end function ubuntu.install_MySQL

ubuntu.install_MariaDB (){

apt-get install -y software-properties-common python-software-properties
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xcbcb082a1bb943db

if [ $maria_version == "5.5" ]; then
    add-apt-repository 'deb http://ftp.osuosl.org/pub/mariadb/repo/5.5/ubuntu saucy main'
fi
if [ $maria_version == "10.0" ]; then
    add-apt-repository 'deb http://ftp.osuosl.org/pub/mariadb/repo/10.0/ubuntu saucy main'
fi

echo "mysql-server mysql-server/root_password password $mysql_pass" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $mysql_pass" | debconf-set-selections

cat > /etc/apt/preferences.d/mariadb.pref <<EOF
Package: *
Pin: release o=MariaDB
Pin-Priority: 1000
EOF

apt-get update

apt-get install -y mariadb-server 
apt-get install -y mariadb-client
apt-get -y install php5-cli php5-mysqlnd php5-mcrypt mcrypt

#Allow MySQL to listen on all interfaces
cp /etc/mysql/my.cnf /etc/mysql/my.cnf.backup
sed -i 's/bind-address           = 127.0.0.1/#bind-address           = 127.0.0.1/' /etc/mysql/my.cnf
/etc/init.d/mysql restart

} #end function ubuntu.install_MariaDB

ubuntu.install_Courier (){

#Install Postfix, Courier, Saslauthd

echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
echo "postfix postfix/mailname string $HOSTNAMEFQDN" | debconf-set-selections
echo "courier-base courier-base/webadmin-configmode boolean false" | debconf-set-selections
echo "courier-ssl courier-ssl/certnotice note" | debconf-set-selections

service sendmail stop; update-rc.d -f sendmail remove
apt-get install -y postfix  postfix-doc courier-authdaemon courier-authlib-mysql courier-pop courier-pop-ssl courier-imap courier-imap-ssl libsasl2-2 libsasl2-modules libsasl2-modules-sql sasl2-bin libpam-mysql openssl courier-maildrop getmail4


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

} #end function ubuntu.install_Courier

ubuntu.install_Dovecot (){

#Install Postfix, Dovecot, Saslauthd
echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
echo "postfix postfix/mailname string $HOSTNAMEFQDN" | debconf-set-selections

service sendmail stop; update-rc.d -f sendmail remove
apt-get install -y postfix postfix-mysql postfix-doc openssl getmail4 dovecot-imapd dovecot-pop3d dovecot-mysql dovecot-sieve 

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

} #end function ubuntu.install_Dovecot

ubuntu.install_Virus (){

#Install Amavisd-new, SpamAssassin, And Clamav
apt-get -y install amavisd-new spamassassin clamav clamav-daemon zoo unzip bzip2 arj nomarch lzop cabextract apt-listchanges libnet-ldap-perl libauthen-sasl-perl clamav-docs daemon libio-string-perl libio-socket-ssl-perl libnet-ident-perl zip libnet-dns-perl

service spamassassin stop
update-rc.d -f spamassassin remove

} #end function ubuntu.install_Virus

ubuntu.install_Apache (){

#Install Apache2, PHP5, phpMyAdmin, FCGI, suExec, Pear, And mcrypt

echo 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2' | debconf-set-selections
#BELOW ARE STILL NOT WORKING
#echo 'phpmyadmin      phpmyadmin/dbconfig-reinstall   boolean false' | debconf-set-selections
#echo 'phpmyadmin      phpmyadmin/dbconfig-install     boolean false' | debconf-set-selections

apt-get install apache2 apache2-doc apache2-utils libapache2-mod-php5 php5 php5-common php5-gd php5-mysql php5-imap phpmyadmin php5-cli php5-cgi libapache2-mod-fcgid apache2-suexec php-pear php-auth php5-mcrypt mcrypt php5-imagick imagemagick libapache2-mod-suphp libruby libapache2-mod-python php5-curl php5-intl php5-memcache php5-memcached php5-ming php5-ps php5-pspell php5-recode php5-snmp php5-sqlite php5-tidy php5-xmlrpc php5-xsl memcached

a2enmod suexec rewrite ssl actions include
a2enmod dav_fs dav auth_digest

#Fix Ming Error
rm /etc/php5/cli/conf.d/ming.ini
cat > /etc/php5/cli/conf.d/ming.ini <<EOF
extension=ming.so
EOF

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

service apache2 restart

} #end function ubuntu.install_Apache2


ubuntu.install_NginX (){

#Install NginX, PHP5, phpMyAdmin, FCGI, suExec, Pear, And mcrypt

echo 'phpmyadmin      phpmyadmin/reconfigure-webserver        multiselect' | debconf-set-selections
echo 'phpmyadmin      phpmyadmin/dbconfig-install     boolean false' | debconf-set-selections

apt-get -y install nginx

service apache2 stop
update-rc.d -f apache2 remove

service nginx start

apt-get -y install php5-fpm php5-curl php5-gd php5-intl php-pear php5-imagick php5-imap php5-memcache php5-ming php5-ps php5-pspell php5-recode php5-snmp php5-sqlite php5-tidy php5-xmlrpc php5-xsl
apt-get -y install php-apc
#PHP Configuration Stuff Goes Here
/etc/init.d/php5-fpm reload
apt-get -y install fcgiwrap

apt-get -y install phpmyadmin

#Remove the Apache2 Stuff for NginX
service apache2 stop
update-rc.d -f apache2 remove
service nginx start

#Fix Ming Error
rm /etc/php5/cli/conf.d/ming.ini
cat > /etc/php5/cli/conf.d/ming.ini <<EOF
extension=ming.so
EOF

/etc/init.d/php5-fpm restart

} #end function ubuntu.install_NginX

ubuntu.install_Mailman (){

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

} #end function ubuntu.install_Mailman

ubuntu.install_PureFTPD (){
#Install PureFTPd
apt-get -y install pure-ftpd-common pure-ftpd-mysql

#Setting up Pure-Ftpd

sed -i 's/VIRTUALCHROOT=false/VIRTUALCHROOT=true/' /etc/default/pure-ftpd-common
echo 1 > /etc/pure-ftpd/conf/TLS
mkdir -p /etc/ssl/private/

openssl req -x509 -nodes -days 7300 -newkey rsa:2048 -subj "/C=/ST=/L=/O=/CN=$(hostname -f)" -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem
chmod 600 /etc/ssl/private/pure-ftpd.pem
/etc/init.d/pure-ftpd-mysql restart

} #end function ubuntu.install_Mailman

ubuntu.install_Quota (){

#Editing FStab
cp /etc/fstab /etc/fstab.backup
sed -i "s/errors=remount-ro/errors=remount-ro,usrjquota=quota.user,grpjquota=quota.group,jqfmt=vfsv0/" /etc/fstab

#Setting up Quota

apt-get -y install quota quotatool
mount -o remount /
quotacheck -avugm
quotaon -avug

} #end function ubuntu.install_Quota

ubuntu.install_Bind (){

#Install BIND DNS Server
apt-get -y install bind9 dnsutils

} #end function ubuntu.install_Bind

ubuntu.install_Stats (){

#Install Vlogger, Webalizer, And AWstats
apt-get -y install vlogger webalizer awstats geoip-database libclass-dbi-mysql-perl

sed -i "s/*/10 * * * * www-data/#*/10 * * * * www-data/" /etc/cron.d/awstats
sed -i "s/10 03 * * * www-data/#10 03 * * * www-data/" /etc/cron.d/awstats

} #end function ubuntu.install_Stats

ubuntu.install_Jailkit (){
#Install Jailkit
apt-get -y install build-essential autoconf automake1.9 libtool flex bison debhelper binutils-gold

cd /tmp
wget http://olivier.sessink.nl/jailkit/jailkit-2.17.tar.gz
tar xvfz jailkit-2.17.tar.gz
cd jailkit-2.17
./debian/rules binary
cd ..
dpkg -i jailkit_2.17-1_*.deb
rm -rf jailkit-2.17*

} #end function ubuntu.install_Jailkit

ubuntu.install_Fail2Ban (){

#Install fail2ban
apt-get install -y fail2ban

} # end function ubuntu.install_Fail2Ban

ubuntu.install_Fail2BanRulesCourier() {

cat > /etc/fail2ban/jail.local <<"EOF"
[pureftpd]
enabled  = true
port     = ftp
filter   = pureftpd
logpath  = /var/log/syslog
maxretry = 3

[postfix-sasl]
enabled  = true
port     = smtp
filter   = sasl
logpath  = /var/log/mail.log
maxretry = 3

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

cat > /etc/fail2ban/filter.d/pureftpd.conf <<"EOF"
[Definition]
failregex = .*pure-ftpd: \(.*@<HOST>\) \[WARNING\] Authentication failed for user.*
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/courierpop3.conf <<"EOF"
[Definition]
failregex = pop3d: LOGIN FAILED.*ip=\[.*:<HOST>\]
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/courierpop3s.conf <<"EOF"
[Definition]
failregex = pop3d-ssl: LOGIN FAILED.*ip=\[.*:<HOST>\]
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/courierimap.conf <<EOF
[Definition]
failregex = imapd: LOGIN FAILED.*ip=\[.*:<HOST>\]
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/courierimaps.conf <<"EOF"
[Definition]
failregex = imapd-ssl: LOGIN FAILED.*ip=\[.*:<HOST>\]
ignoreregex =
EOF

/etc/init.d/fail2ban restart

} # end function ubuntu.install_Fail2BanRuleCourier

ubuntu.install_Fail2BanRulesDovecot() {

cat > /etc/fail2ban/jail.local <<"EOF"
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

[postfix-sasl]
enabled  = true
port     = smtp
filter   = postfix-sasl
logpath  = /var/log/mail.log
maxretry = 3
EOF

cat > /etc/fail2ban/filter.d/pureftpd.conf <<"EOF"
[Definition]
failregex = .*pure-ftpd: \(.*@<HOST>\) \[WARNING\] Authentication failed for user.*
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/dovecot-pop3imap.conf <<"EOF"
[Definition]
failregex = (?: pop3-login|imap-login): .*(?:Authentication failure|Aborted login \(auth failed|Aborted login \(tried to use disabled|Disconnected \(auth failed|Aborted login \(\d+ authentication attempts).*rip=(?P<host>\S*),.*
ignoreregex =
EOF

echo "ignoreregex =" >> /etc/fail2ban/filter.d/postfix-sasl.conf

service fail2ban restart

} # end function ubuntu.install_Fail2BanRuleDovecot

ubuntu.install_SquirrelMail (){

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

if [ $web_server == "NginX" ]; then
#Remove the Apache2 Stuff for NginX
apt-get remove --purge -y apache2*
/etc/init.d/nginx start
fi

} #end function ubuntu.install_SquirrelMail
