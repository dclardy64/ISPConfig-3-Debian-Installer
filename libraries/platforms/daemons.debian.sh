#!/bin/bash
# Functions For Handling Daemon Management In Debian Linux

# Add Daemon
function daemon_add() {
	if [ -e /etc/init.d/$1 ]; then
		update-rc.d $1 defaults
	fi
}

# Remove Daemon
function daemon_remove() {
	if [ -e /etc/init.d/$1 ]; then
		update-rc.d -f $1 remove
	fi
}

# Enable Daemon
function daemon_enable() {
	if [ -e /etc/init.d/$1 ]; then
		update-rc.d $1 enable
	fi
}

# Disable Daemon
function daemon_disable() {
	if [ -e /etc/init.d/$1 ]; then
		update-rc.d $1 disable
	fi
}

# Manage Daemon
function daemon_manage() {
	if [ -e /etc/init.d/$1 ]; then
		invoke-rc.d $1 $2
	fi
}
