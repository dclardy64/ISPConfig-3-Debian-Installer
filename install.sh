#!/bin/bash

###############################################################################################
# Complete ISPConfig setup script for Debian/Ubuntu Systems         						  #
# Drew Clardy												                                  # 
# http://drewclardy.com				                                                          #
# http://github.com/dclardy64/ISPConfig-3-Debian-Install                                      #
###############################################################################################

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use the root user to install the software."
    exit 1
fi

if [ ! -f /usr/local/ispconfig/interface/lib/config.inc.php ]; then
    ISPConfig_Installed=No
elif [ -f /usr/local/ispconfig/interface/lib/config.inc.php ]; then
	ISPConfig_Installed=Yes
fi

# Load Variables
source config.sh

###############
## Libraries ##
###############

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
	source $FUNCTIONPATH/$DISTRIBUTION.functions.sh
elif [ $DISTRIBUTION == "ubuntu" ]; then
	source $FUNCTIONPATH/$DISTRIBUTION.functions.sh
fi

# Load Generic Functions
source $FUNCTIONPATH/generic.functions.sh

# Load Extras
for file in $EXTRAPATH/*.install.sh; do
	source $file
done


#Execute functions#
if [ $ISPConfig_Installed = "No" ]; then
	install_Questions
	$DISTRIBUTION.install_Repos
	header "Installing Basics..."
	install_Basic
	if [ $DISTRIBUTION == "ubuntu" ]; then
		ubuntu.install_DisableAppArmor
	fi
	header "Installing Database Selection..."
	if [ $sql_server == "MySQL" ]; then
		$DISTRIBUTION.install_MySQL
	fi
	if [ $sql_server == "MariaDB" ]; then
		$DISTRIBUTION.install_MariaDB
	fi
	header "Installing Mail Server Selection..."
	if [ $install_mail_server == "Yes" ]; then
		if [ $mail_server == "Courier" ]; then
			$DISTRIBUTION.install_Courier
		elif [ $mail_server == "Dovecot" ]; then
			$DISTRIBUTION.install_Dovecot
		fi
		$DISTRIBUTION.install_Virus
	fi
	header "Installing Web Server Selection..."
	if [ $install_web_server == "Yes" ]; then
		if [ $web_server == "Apache" ]; then
			$DISTRIBUTION.install_Apache
		elif [ $web_server == "NginX" ]; then
			$DISTRIBUTION.install_NginX
		fi
		$DISTRIBUTION.install_Stats
	fi
	if [ $mailman == "Yes" ]; then
		header "Installing Mailman..."
		$DISTRIBUTION.install_Mailman
	fi
	if [ $install_ftp_server == "Yes" ]; then
		header "Installing FTP Server..."
		$DISTRIBUTION.install_PureFTPD
	fi
	if [ $install_dns_server == "Yes" ]; then
		header "Installing DNS Server..."
		$DISTRIBUTION.install_Bind
	fi
	if [ $quota == "Yes" ]; then
		header "Installing Quota..."
		$DISTRIBUTION.install_Quota
	fi
	if [ $jailkit == "Yes" ]; then
		header "Installing Jailkit..."
		$DISTRIBUTION.install_Jailkit
	fi
	header "Installing Fail2Ban..."
	$DISTRIBUTION.install_Fail2Ban
	if [ $mail_server == "Courier" ]; then
		$DISTRIBUTION.install_Fail2BanRulesCourier
	fi
	if [ $mail_server == "Dovecot" ]; then
		$DISTRIBUTION.install_Fail2BanRulesDovecot
	fi
	header "Installing SquirrelMail..."
	$DISTRIBUTION.install_SquirrelMail
	header "Installing ISPConfig3..."
	install_ISPConfig
elif [ $ISPConfig_Installed == "Yes" ]; then
	warning "ISPConfig 3 already installed! Asking about extra installation scripts."
	install_Extras
	if [ $extras == "Yes" ]; then
		if [ $extra_stuff == "Themes" ]; then
			theme_questions
			if [ $theme == "ISPC-Clean" ]; then
				function_install_ISPC_Clean
			fi
		elif [ $extra_stuff == "RoundCube" ]; then
			roundcube_questions
			if [ $web_server == "Apache" ]; then
				RoundCube_install_Apache
			elif [ $web_server == "NginX" ]; then
				RoundCube_install_NginX
			fi
		fi
	fi
fi