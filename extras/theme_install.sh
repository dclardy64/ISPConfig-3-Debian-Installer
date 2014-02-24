#!/bin/bash

###############################################################################################
# Theme Installation for ISPConfig 3 setup.              						 			                    #
# Drew Clardy																				                                          #
# http://drewclardy.com							                                                          #
###############################################################################################

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use the root user to install the software."
    exit 1
fi

back_title="ISPConfig 3 Theme Installer"

questions (){
  while [ "x$theme" == "x" ]
  do
    theme=$(whiptail --title "Theme" --backtitle "$back_title" --nocancel --radiolist "Select Theme" 10 50 2 "ISPC-Clean" "(default)" ON "Other" "" OFF 3>&1 1>&2 2>&3)
  done
  while [ "x$mysql_pass" == "x" ]
  do
    mysql_pass=$(whiptail --title "MySQL Root Password" --backtitle "$back_title" --inputbox "Please insert the MySQL Root Password" --nocancel 10 50 3>&1 1>&2 2>&3)
  done
}


function_install_ISPC_Clean() {

  # Get Theme
  cd /tmp
  wget https://github.com/dclardy64/ISPConfig_Clean-3.0.5/archive/master.zip
  unzip master.zip
  cd ISPConfig_Clean-3.0.5-master
  cp -R interface/* /usr/local/ispconfig/interface/

  sed -i "s|\$conf\['theme'\] = 'default'|\$conf\['theme'\] = 'ispc-clean'|" /usr/local/ispconfig/interface/lib/config.inc.php
  sed -i "s|\$conf\['logo'\] = 'themes/default|\$conf\['logo'\] = 'themes/ispc-clean|" /usr/local/ispconfig/interface/lib/config.inc.php

  mysql -u root -p$mysql_pass < sql/ispc-clean.sql

}

#Execute functions#
if [ -f /etc/debian_version ]; then 
	questions
  if [ $theme == "ISPC-Clean" ]; then
    function_install_ISPC_Clean
  fi
else echo "Unsupported Linux Distribution."
fi		

#End execute functions#