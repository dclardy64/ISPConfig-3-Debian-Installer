#!/bin/bash
# Functions For Checking Package/Repository Installation Status In Ubuntu Linux

# Check If Package Installed
function check_package() {
	dpkg -l $1 2> /dev/null | egrep -q ^ii
}

# Check If Repository Installed
function check_repository() {
	grep -iq $1 /etc/apt/sources.list || [ -f /etc/apt/sources.list.d/$1.list ]
}
