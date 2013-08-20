#!/bin/bash

###############################################################################################
# RoundCube Setup ISPConfig setup.                      						 			  #
# Drew Clardy																				  #
# http://drewclardy.com							                                              #
###############################################################################################

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use the root user to install the software."
    exit 1
fi

back_title="ISPConfig 3 RoundCube Installer"

questions (){
  while [ "x$web_server" == "x" ]
  do
    web_server=$(whiptail --title "Web Server" --backtitle "$back_title" --nocancel --radiolist "Select Web Server Software" 10 50 2 "Apache" "(default)" ON "NginX" "" OFF 3>&1 1>&2 2>&3)
  done
  while [ "x$mysql_pass" == "x" ]
  do
    mysql_pass=$(whiptail --title "MySQL Root Password" --backtitle "$back_title" --inputbox "Please specify a MySQL Root Password" --nocancel 10 50 3>&1 1>&2 2>&3)
  done
  while [ "x$roundcube_db" == "x" ]
  do
    roundcube_db=$(whiptail --title "MySQL Root Password" --backtitle "$back_title" --inputbox "Please specify a RoundCube Database" --nocancel 10 50 3>&1 1>&2 2>&3)
  done
  while [ "x$roundcube_user" == "x" ]
  do
    roundcube_user=$(whiptail --title "MySQL Root Password" --backtitle "$back_title" --inputbox "Please specify a RoundCube User" --nocancel 10 50 3>&1 1>&2 2>&3)
  done
  while [ "x$roundcube_pass" == "x" ]
  do
    roundcube_pass=$(whiptail --title "MySQL Root Password" --backtitle "$back_title" --inputbox "Please specify a RoundCube User Password" --nocancel 10 50 3>&1 1>&2 2>&3)
  done
}

function_install_Apache() {
	echo "This is not done at this time. Check back later. It should be soon."
}

function_install_NginX() {
	#Make RoundCube Directory
	mkdir -p /var/www/roundcube 

	#RoundCube Download
	cd /tmp
	wget http://downloads.sourceforge.net/project/roundcubemail/roundcubemail/0.9.2/roundcubemail-0.9.2.tar.gz
	tar xvfz roundcubemail-0.9.2.tar.gz
	cd roundcubemail-0.9.2/
	mv * /var/www/roundcube/

	chown -R www-data:www-data /var/www/roundcube

	mysql -uroot -p$mysql_pass -e "CREATE DATABASE $roundcube_db;"
	mysql -uroot -p$mysql_pass -e "GRANT ALL PRIVILEGES ON $roundcube_db.* TO '$roundcube_user'@'localhost' IDENTIFIED BY '$roundcube_pass';"
    mysql -uroot -p$mysql_pass -e "GRANT ALL PRIVILEGES ON $roundcube_db.* TO '$roundcube_user'@'localhost.localdomain' IDENTIFIED BY '$roundcube_pass';"
    mysql -uroot -p$mysql_pass -e "FLUSH PRIVILEGES;"

    cat > /etc/nginx/sites-available/webmail.vhost <<EOF
    server {
        listen 80;
        server_name webmail.*;

        index index.php index.html;
        root /var/www/roundcube;

        location ~ ^/favicon.ico$ {
	    	root /var/www/roundcube/skins/default/images;
	        log_not_found off;
	        access_log off;
	        expires max;
        }

        location = /robots.txt {
            allow all;
            log_not_found off;
            access_log off;
        } 

        location ~ ^/(README|INSTALL|LICENSE|CHANGELOG|UPGRADING)$ {
            deny all;
        }

        location ~ ^/(bin|SQL)/ {
            deny all;
        }

        location ~ /\. {
            deny all;
            access_log off;
            log_not_found off;
        }

        location ~ \.php$ {
            try_files $uri =404;
            include /etc/nginx/fastcgi_params;
            fastcgi_pass unix://var/run/php5-fpm.sock;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_index index.php;
        }
	}
EOF

    cd /etc/nginx/sites-enabled/
    ln -s /etc/nginx/sites-available/webmail.vhost webmail.vhost

	/etc/init.d/nginx reload

	cd /var/www/roundcube/config
	mv db.inc.php.dist db.inc.php
	mv main.inc.php.dist main.inc.php
	
	sed -i 's|$rcmail_config['db_dsnw'] = 'mysql://roundcube:pass@localhost/roundcubemail';|$rcmail_config['db_dsnw'] = 'mysql://$roundcube_user:$roundcube_pass@localhost/$roundcube_db';|' /var/www/roundcube/config/db.inc.php

	sed -i 's|$rcmail_config['default_host'] = '';|$rcmail_config['default_host'] = '%s';|' /var/www/roundcube/config/main.inc.php
	sed -i 's|$rcmail_config['smtp_server'] = '';|$rcmail_config['smtp_server'] = '%h';|' /var/www/roundcube/config/main.inc.php

	rm -rf /var/www/roundcube/installer
}

#Execute functions#
if [ -f /etc/debian_version ]; then 
	questions
  	if [ $web_server == "Apache" ]; then
		function_install_Apache
	fi
	if [ $web_server == "NginX" ]; then
		function_install_NginX
	fi
else echo "Unsupported Linux Distribution."
fi		

#End execute functions#