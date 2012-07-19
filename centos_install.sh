#!/bin/bash
###############################################################################################
# Complete ISPConfig setup script for CentOS 6.									 			  #
# Drew Clardy																				  #
# http://drewclardy.com							                                              #
###############################################################################################

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install the software."
    exit 1
fi

clear
echo "================================================================================"
echo "ISPConfig 3 Setup Script ,  Written by Drew Clardy with help from other scripts!"
echo "================================================================================"
echo "A tool to auto-install ISPConfig and its dependencies "
echo "================================================================================"
echo "Please have Server IP and Hostname Ready!"
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
   
#set Web Server

    web_server="Apache"
	echo "Please select Web Server (Apache or NginX):"
	read -p "(Default Web Server: Apache):" web_server
    if [ "$web_server" = "" ]; then
    	web_server="Apache"
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
    
#set Mailman
    mailman="Yes"
    echo "Please select whether to install Mailman or Not:"
    read -p "(Default: Yes):" mailman
    if [ "$mailman" = "" ]; then
        mailmam="Yes"
    fi
    echo "==========================="
    echo "mailman=$mailman"
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
    
fi

centos_install_basic (){

    #Set hostname and FQDN
    sed -i "s/${serverIP}.*/${serverIP} ${HOSTNAMEFQDN} ${HOSTNAME}/" /etc/hosts

    #Configure the Firewall
    echo "======================================="
    echo "Firewall Configuartion. Set to disabled"
    echo "======================================="
    echo "Press ENTER to continue.."
    read DUMMY
    system-config-firewall

    #Disable SELinux
    sed -i "s/SELINUX=*/SELINUX=disabled/" /etc/selinux/config

} #end function centos_install_basic

centos_add_repos (){

    #Import GPG Keys
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY*

    #Import RPMForge and EPEL repos
    rpm --import http://dag.wieers.com/rpm/packages/RPM-GPG-KEY.dag.txt

    cd /tmp
    wget http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.2-2.el6.rf.x86_64.rpm
    rpm -ivh rpmforge-release-0.5.2-2.el6.rf.x86_64.rpm

    rpm --import https://fedoraproject.org/static/0608B895.txt
    wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-7.noarch.rpm
    rpm -ivh epel-release-6-7.noarch.rpm

    #Set Priorities
    yum install yum-priorities
    sed -i "s/prioity=*/priority=10/" /etc/yum.repos.d/epel.repo

    #Update
    yum update

    #Install Development tools
    yum groupinstall 'Development Tools'

} #end function centos_add_repos

centos_install_quotas (){

    #Install quota
    yum install quota

    #Editing FStab
    sed -i "s/defaults/defaults,usrjquota=quota.user,grpjquota=quota.group,jqfmt=vfsv0/" /etc/fstab

    #Setting up Quota

    mount -o remount /
    quotacheck -avugm
    quotaon -avug

} #end function centos_install_quotas

centos_install_Apache_Mysql_phpMyAdmin (){

    yum install ntp httpd mod_ssl mysql-server php php-mysql php-mbstring phpmyadmin

} #end function centos_install_Apache_Mysql_phpMyAdmin

centos_install_courier () {

    #Remove Dovecot
    yum remove dovecot dovecot-mysql

    #Install Prerequisites
    yum install rpm-build gcc mysql-devel openssl-devel cyrus-sasl-devel pkgconfig zlib-devel pcre-devel openldap-devel postgresql-devel expect libtool-ltdl-devel openldap-servers libtool gdbm-devel pam-devel gamin-devel libidn-devel

    #Create user to build Courier
    useradd -m -s /bin/bash courierbuild
    passwd courierbuild
}