ISPConfig 3 Installer
=====================

This script will install all of the necessary programs and changes that need to be made to get ISPConfig running successfully. It uses the Perfect Server guide from Falko Timme as the
guide. If you would like, you can manually install all of the things needed using the guides that he has provided. I am just trying to streamline the process. 

There are some things to note.

1. I edited your fstab for the Quota installation. I only do this when you select to install Quota. This will not work on OpenVZ containers.
2. I make no guarantees that this will work for you. It should, but I am not responsible for anything that happens to your system. It should be installed on a clean install. If you choose
not to follow these directions, you are responsible for the damage that you have done.

Installation Instructions:
--------------------------

1. Run this command:

	```bash
	cd /tmp; wget --no-check-certificate -O ISPConfig3.tgz https://github.com/dclardy64/ISPConfig-3-Debian-Installer/tarball/master; tar zxvf ISPConfig3.tgz; cd *Installer*; bash install.sh
	```

2. Answer the onscreen prompts. The script stops so that you can see the appropriate answers.
3. Enjoy the completed installation.


Extra Installation Instructions:
------------------------------------

1. Please make sure that you have set the PHP Timezone in the appropriate files.
2. Run this command:

	```bash
	cd /tmp; wget --no-check-certificate -O ISPConfig3.tgz https://github.com/dclardy64/ISPConfig-3-Debian-Installer/tarball/master; tar zxvf ISPConfig3.tgz; cd *Installer*; bash install.sh
	```
3. Answer the onscreen prompts.
4. Enjoy the completed installation. 


TO DO
-----

See what other options I can add. Please feel free to submit an issue for any ideas that you have.
