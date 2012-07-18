#!/bin/bash
rake apache:vhostfiles

FOUND=0
FILENAME="karaoke-files.local.conf"
LOCALHOSTREF="127.0.0.1 $FILENAME"

if [ -d "/etc/apache2/sites-available" ]; then
	FOUND=1
	sudo cp $FILENAME /etc/apache2/sites-available
fi
if [ -d "/etc/apache2/other" ]; then
	FOUND=1
	sudo cp $FILENAME /etc/apache2/other
fi

if [ $FOUND == "1" ]; then
	if [ -f "a2ensite" ]; then
		sudo a2ensite $FILENAME
		echo "Config enabled."
	fi
	if [ -f "/etc/hosts" ]; then
		if grep -Fxq "$LOCALHOSTREF" /etc/hosts
		then
			echo $LOCALHOSTREF | sudo tee -a /etc/hosts
			echo "Hosts file updated."
		fi
	fi
	echo "Restart apache to activate karaoke-files.local."
	echo "Note: if karaoke-files.local keeps giving you 403 errors, try adding"
	echo "NameVirtualHost *:80"
	echo "to your httpd.conf file."
fi

