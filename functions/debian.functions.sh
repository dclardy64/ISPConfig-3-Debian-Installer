#!/bin/bash

###############################################################################################
# Complete ISPConfig setup script for Debian/Ubuntu Systems         						  #
# Drew Clardy												                                  # 
# http://drewclardy.com				                                                          #
# http://github.com/dclardy64/ISPConfig-3-Debian-Install                                      #
###############################################################################################

debian.install_Repos (){

#Updates server and install commonly used utilities
cp /etc/apt/sources.list /etc/apt/sources.list.backup
echo '' >> /etc/apt/sources.list
sed -i ':a;N;$!ba;s/main\n/main contrib non-free\n/g' /etc/apt/sources.list

cat > /etc/apt/sources.list.d/dotdeb.list <<EOF
# DotDeb
deb http://packages.dotdeb.org wheezy all
deb-src http://packages.dotdeb.org wheezy all

EOF

wget http://www.dotdeb.org/dotdeb.gpg
cat dotdeb.gpg | apt-key add - 

apt-get update
} #end function debian.install_Repos

debian.install_MySQL () {

echo "mysql-server-5.6 mysql-server/root_password password $mysql_pass" | debconf-set-selections
echo "mysql-server-5.6 mysql-server/root_password_again password $mysql_pass" | debconf-set-selections

#Install MySQL
apt-get install -y mysql-server
apt-get install -y mysql-client 
apt-get -y install php5-cli php5-mysqlnd php5-mcrypt mcrypt

#Allow MySQL to listen on all interfaces
cp /etc/mysql/my.cnf /etc/mysql/my.cnf.backup
sed -i 's/bind-address           = 127.0.0.1/#bind-address           = 127.0.0.1/' /etc/mysql/my.cnf
/etc/init.d/mysql restart

} #end function debian.install_MySQL

debian.install_MariaDB (){

apt-get install -y python-software-properties
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xcbcb082a1bb943db

if [ $maria_version == "5.5" ]; then
	add-apt-repository 'deb http://nyc2.mirrors.digitalocean.com/mariadb/repo/5.5/debian wheezy main'
elif [ $maria_version == "10.0" ]; then
	add-apt-repository 'deb http://nyc2.mirrors.digitalocean.com/mariadb/repo/10.0/debian wheezy main'
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

} #end function debian.install_MariaDB

debian.install_Courier (){

#Install Postfix, Courier, Saslauthd

echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
echo "postfix postfix/mailname string $HOSTNAMEFQDN" | debconf-set-selections
echo "courier-base courier-base/webadmin-configmode boolean false" | debconf-set-selections
echo "courier-ssl courier-ssl/certnotice note" | debconf-set-selections

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

} #end function debian.install_Courier

debian.install_Dovecot (){

#Install Postfix, Dovecot, Saslauthd
echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
echo "postfix postfix/mailname string $HOSTNAMEFQDN" | debconf-set-selections

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

} #end function debian.install_Dovecot

debian.install_Virus (){

#Install Amavisd-new, SpamAssassin, And Clamav
apt-get install -y amavisd-new spamassassin clamav clamav-daemon zoo arj nomarch lzop cabextract apt-listchanges libnet-ldap-perl libauthen-sasl-perl clamav-docs daemon libio-string-perl libio-socket-ssl-perl libnet-ident-perl libnet-dns-perl

/etc/init.d/spamassassin stop
insserv -rf spamassassin

} #end function debian.install_Virus

debian.install_Apache (){

echo "========================================================================="
echo "You will be prompted for some information during the install of phpmyadmin."
echo "Select NO when asked to configure using dbconfig-common"
echo "Please enter them where needed."
echo "========================================================================="
echo "Press ENTER to continue.."
read DUMMY

#Install Apache2, PHP5, phpMyAdmin, FCGI, suExec, Pear, And mcrypt

echo 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2' | debconf-set-selections
#BELOW ARE STILL NOT WORKING
#echo 'phpmyadmin      phpmyadmin/dbconfig-reinstall   boolean false' | debconf-set-selections
#echo 'phpmyadmin      phpmyadmin/dbconfig-install     boolean false' | debconf-set-selections

apt-get install -y apache2 apache2.2-common apache2-doc apache2-mpm-prefork apache2-utils libexpat1 ssl-cert libapache2-mod-php5 php5-common php5-gd php5-imap phpmyadmin php5-cgi libapache2-mod-fcgid apache2-suexec php-pear php-auth php5-imagick imagemagick libapache2-mod-suphp libruby libapache2-mod-ruby libapache2-mod-python php5-curl php5-intl php5-memcache php5-memcached php5-ming php5-ps php5-pspell php5-recode php5-snmp php5-sqlite php5-tidy php5-xmlrpc php5-xsl memcached

a2enmod suexec rewrite ssl actions include
a2enmod dav_fs dav auth_digest

#Fix Ming Error
rm /etc/php5/cli/conf.d/ming.ini
cat > /etc/php5/cli/conf.d/ming.ini <<"EOF"
extension=ming.so
EOF

#Fix SuPHP
cp /etc/apache2/mods-available/suphp.conf /etc/apache2/mods-available/suphp.conf.backup
rm /etc/apache2/mods-available/suphp.conf
cat > /etc/apache2/mods-available/suphp.conf <<"EOF"
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

#Enable Ruby Support
sed -i 's|application/x-ruby|#application/x-ruby|' /etc/mime.types

#Install XCache
apt-get install -y php5-xcache



#Restart Apache
/etc/init.d/apache2 restart

} # end function debian.install_Apache

debian.install_NginX (){

#Install NginX, PHP5, phpMyAdmin, FCGI, suExec, Pear, And mcrypt

echo 'phpmyadmin      phpmyadmin/reconfigure-webserver        multiselect' | debconf-set-selections
echo 'phpmyadmin      phpmyadmin/dbconfig-install     boolean false' | debconf-set-selections

apt-get install -y nginx
/etc/init.d/apache2 stop
update-rc.d -f apache2 remove
/etc/init.d/nginx start

apt-get install -y php5-fpm
apt-get install -y php5-curl php5-gd php5-intl php-pear php5-imagick php5-imap php5-memcache php5-memcached php5-ming php5-ps php5-pspell php5-recode php5-snmp php5-sqlite php5-tidy php5-xmlrpc php5-xsl memcached
apt-get install -y php-apc
#PHP Configuration Stuff Goes Here
apt-get install -y fcgiwrap

echo "========================================================================="
echo "You will be prompted for some information during the install of phpmyadmin."
echo "Please enter them where needed."
echo "========================================================================="
echo "Press ENTER to continue.."
read DUMMY

DEBIAN_FRONTEND=noninteractive apt-get install -y dbconfig-common
apt-get install -y phpmyadmin

#Remove the Apache2 Stuff for NginX
/etc/init.d/apache2 stop
insserv -r apache2
/etc/init.d/nginx start

#Fix Ming Error
rm /etc/php5/cli/conf.d/ming.ini
cat > /etc/php5/cli/conf.d/ming.ini <<"EOF"
extension=ming.so
EOF

/etc/init.d/php5-fpm restart

} # end function debian.install_NginX

debian.install_Mailman (){

echo "================================================================================================"
echo "You will be prompted for some information during the install."
echo "Select the languages you want to support and hit OK when told about the missing site list"
echo "You will also be asked for the email address of person running the list & password for the list."
echo "Please enter them where needed."
echo "================================================================================================"
echo "Press ENTER to continue.."
read DUMMY

#Install Mailman
apt-get install -y mailman
newlist mailman

mv /etc/aliases /etc/aliases.backup

cat > /etc/aliases.mailman <<"EOF"
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

} # end function debian.install_Mailman

debian.install_PureFTPD (){

#Install PureFTPd
apt-get install -y pure-ftpd-common pure-ftpd-mysql

#Setting up Pure-Ftpd
sed -i 's/VIRTUALCHROOT=false/VIRTUALCHROOT=true/' /etc/default/pure-ftpd-common
echo 1 > /etc/pure-ftpd/conf/TLS
mkdir -p /etc/ssl/private/

openssl req -x509 -nodes -days 7300 -newkey rsa:2048 -subj "/C=/ST=/L=/O=/CN=$(hostname -f)" -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem
chmod 600 /etc/ssl/private/pure-ftpd.pem
/etc/init.d/pure-ftpd-mysql restart

} # end function debian.install_Mailman

debian.install_Quota (){

#Editing FStab
cp /etc/fstab /etc/fstab.backup
sed -i "s/errors=remount-ro/errors=remount-ro,usrjquota=quota.user,grpjquota=quota.group,jqfmt=vfsv0/" /etc/fstab

#Setting up Quota
apt-get install -y quota quotatool
mount -o remount /
quotacheck -avugm
quotaon -avug

} # end function debian.install_Quota

debian.install_Bind (){

#Install BIND DNS Server
apt-get install -y bind9 dnsutils

} # end function debian.install_Binf

debian.install_Stats (){

#Install Vlogger, Webalizer, And AWstats
apt-get install -y vlogger webalizer awstats geoip-database libclass-dbi-mysql-perl

sed -i "s/*/10 * * * * www-data/#*/10 * * * * www-data/" /etc/cron.d/awstats
sed -i "s/10 03 * * * www-data/#10 03 * * * www-data/" /etc/cron.d/awstats

} # end function debian.install_Stats

debian.install_Jailkit (){

#Install Jailkit
apt-get install -y build-essential autoconf automake1.9 libtool flex bison debhelper binutils-gold

cd /tmp
wget http://olivier.sessink.nl/jailkit/jailkit-2.17.tar.gz
tar xvfz jailkit-2.17.tar.gz
cd jailkit-2.17
./debian/rules binary
cd ..
dpkg -i jailkit_2.17-1_*.deb
rm -rf jailkit-2.17*

} # end function debian.install_Jailkit

debian.install_Fail2Ban (){

#Install fail2ban
apt-get install -y fail2ban

} # end function debian.install_Fail2Ban

debian.install_Fail2BanRulesCourier() {

cat > /etc/fail2ban/jail.local <<"EOF"
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

} # end function debian.install_Fail2BanRuleCourier

debian.install_Fail2BanRulesDovecot() {

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

[sasl]
enabled  = true
port     = smtp
filter   = sasl
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

/etc/init.d/fail2ban restart

} # end function debian.install_Fail2BanRuleDovecot

debian.install_SquirrelMail (){

echo "==========================================================================================="
echo "When prompted, type D! Then type the mailserver you choose ($mail_server),"
echo "and hit enter. Type S, Hit Enter. Type Q, Hit Enter."
echo "==========================================================================================="
echo "Press ENTER to continue.."
read DUMMY

#Install SquirrelMail
apt-get install -y squirrelmail
squirrelmail-configure

if [ $web_server == "Apache" ]; then
mv /etc/squirrelmail/apache.conf /etc/squirrelmail/apache.conf.backup
cat > /etc/squirrelmail/apache.conf <<"EOF"
Alias /squirrelmail /usr/share/squirrelmail
Alias /webmail /usr/share/squirrelmail

<Directory /usr/share/squirrelmail>
	Options FollowSymLinks
	<IfModule mod_php5.c>
		AddType application/x-httpd-php .php
		php_flag magic_quotes_gpc Off
		php_flag track_vars On
		php_admin_flag allow_url_fopen Off
		php_value include_path .
		php_admin_value upload_tmp_dir /var/lib/squirrelmail/tmp
		php_admin_value open_basedir /usr/share/squirrelmail:/etc/squirrelmail:/var/lib/squirrelmail:/etc/hostname:/etc/mailname
		php_flag register_globals off
	</IfModule>
	<IfModule mod_dir.c>
		DirectoryIndex index.php
	</IfModule>

	# access to configtest is limited by default to prevent information leak
	<Files configtest.php>
		order deny,allow
		deny from all
		allow from 127.0.0.1
	</Files>
</Directory>

# users will prefer a simple URL like http://webmail.example.com
#<VirtualHost 1.2.3.4>
#  DocumentRoot /usr/share/squirrelmail
#  ServerName webmail.example.com
#</VirtualHost>

# redirect to https when available (thanks omen@descolada.dartmouth.edu)
#
#  Note: There are multiple ways to do this, and which one is suitable for
#  your site's configuration depends. Consult the apache documentation if
#  you're unsure, as this example might not work everywhere.
#
#<IfModule mod_rewrite.c>
#  <IfModule mod_ssl.c>
#    <Location /squirrelmail>
#      RewriteEngine on
#      RewriteCond %{HTTPS} !^on$ [NC]
#      RewriteRule . https://%{HTTP_HOST}%{REQUEST_URI}  [L]
#    </Location>
#  </IfModule>
#</IfModule>
EOF

mkdir /var/lib/squirrelmail/tmp
chown www-data /var/lib/squirrelmail/tmp
ln -s /etc/squirrelmail/apache.conf /etc/apache2/conf.d/squirrelmail.conf
/etc/init.d/apache2 reload

fi

if [ $web_server == "NginX" ]; then
#Remove the Apache2 Stuff for NginX
apt-get remove --purge -y apache2*
/etc/init.d/nginx start
fi

} # end function debian.install_SquirrelMail	
