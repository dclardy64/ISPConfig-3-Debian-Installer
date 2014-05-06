#!/bin/bash
# Functions For Detecting Current Distribution

# Debian Detection (Issue File)
if grep -iq "debian" /etc/issue; then
	# Set Distribution To Debian
	DISTRIBUTION=debian
fi

# Debian Detection (LSB Release)
if command -v lsb_release &> /dev/null; then
	if lsb_release -a 2> /dev/null | grep -iq "debian"; then
		# Set Distribution To Debian
		DISTRIBUTION=debian
	fi
fi

# Ubuntu Detection (Issue File)
if grep -iq "ubuntu" /etc/issue; then
	# Set Distribution To Ubuntu
	DISTRIBUTION=ubuntu
fi

# Ubuntu Detection (LSB Release)
if command -v lsb_release &> /dev/null; then
	if lsb_release -a 2> /dev/null | grep -iq "ubuntu"; then
		# Set Distribution To Ubuntu
		DISTRIBUTION=ubuntu
	fi
fi