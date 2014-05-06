#!/bin/bash
# Functions For Displaying Messages & Headers

# Print Header
function header() {
	echo -e "\e[1;34m>> \e[1;37m$* \e[1;34m<<\e[0m"
}

# Print Subheader
function subheader() {
	echo -e "\e[1;32m>> \e[1;37m$*\e[0m"
}

# Print Error Message
function error() {
	echo -e "\e[1;31m$*\e[0m"
}

# Print Warning Message
function warning() {
	echo -e "\e[1;33m$*\e[0m"
}