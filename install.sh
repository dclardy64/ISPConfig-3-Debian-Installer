#!/bin/bash

###############################################################################################
# Complete ISPConfig setup script for Debian/Ubuntu Systems         						  #
# Drew Clardy												                                  #
# http://drewclardy.com				                                                          #
# http://github.com/dclardy64/ISPConfig-3-Debian-Instal                                       #
###############################################################################################

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use the root user to install the software."
    exit 1
fi

# Load Variables
source config.sh

###############
## Libraries ##
###############

# Load Libraries (External)
for file in $LIBRARYPATH/external/*.sh; do
	# Source Libraries
	source $file
done

# Load Libraries
for file in $LIBRARYPATH/*.sh; do
	# Source Libraries
	source $file
done

# Check Distribution
if [ $DISTRIBUTION = "none" ]; then
	# Error Message
	error "Your distribution is unsupported! If you are sure that your distribution is supported please install the lsb-release package as it will improve detection."
	# Exit If Not Supported
	exit
fi

# Load Libraries (Distribution Specific)
for file in $LIBRARYPATH/platforms/*.$DISTRIBUTION.sh; do
	# Source Scripts
	source $file
done

# Load Functions (Distribution Specific)
if [ $DISTRIBUTION == "debian" ]; then
	source $FUNCTIONPATH/$DISTRIBUTION_functions.sh
elif [ $DISTRIBUTION == "ubuntu" ]; then
	source $FUNCTIONPATH/$DISTRIBUTION_functions.sh
fi
source $FUNCTIONPATH/generic_functions.sh



#Execute functions#
questions
install_basic
install_DashNTP
if [ $sql_server == "MySQL" ]; then
	$DISTRIBUTION_install_MySQL
fi
if [ $sql_server == "MariaDB" ]; then
	$DISTRIBUTION_install_MariaDB
fi
if [ $mail_server == "Courier" ]; then
	$DISTRIBUTION_install_Courier
fi
if [ $mail_server == "Dovecot" ]; then
	$DISTRIBUTION_install_Dovecot
fi
$DISTRIBUTION_install_Virus
if [ $web_server == "Apache" ]; then
	$DISTRIBUTION_install_Apache
fi
if [ $web_server == "NginX" ]; then
	$DISTRIBUTION_install_NginX
fi
if [ $mailman == "Yes" ]; then
	$DISTRIBUTION_install_Mailman
fi
$DISTRIBUTION_install_PureFTPD
if [ $quota == "Yes" ]; then
	$DISTRIBUTION_install_Quota
fi
$DISTRIBUTION_install_Bind
$DISTRIBUTION_install_Stats
if [ $jailkit == "Yes" ]; then
	$DISTRIBUTION_install_Jailkit
fi
$DISTRIBUTION_install_Fail2Ban
if [ $mail_server == "Courier" ]; then
	$DISTRIBUTION_install_Fail2BanRulesCourier
fi
if [ $mail_server == "Dovecot" ]; then
	$DISTRIBUTION_install_Fail2BanRulesDovecot
fi
$DISTRIBUTION_install_SquirrelMail
install_ISPConfig



