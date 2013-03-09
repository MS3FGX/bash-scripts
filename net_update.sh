#!/bin/bash
# Prototype Internet-update engine for Bash scripts

# Global variables
APPNAME="net_update"
BASEURL="ftp://ftp.digifail.com/updates/"
VER="0.9"

ErrorMsg ()
{
# ErrorMsg <Error Type> <Error Message>
# Displays either a minor (warning) or critical error, exiting on an critical.
# If message starts with "n", a newline is printed before message.
[[ $(expr substr "$2" 1 1) == "n" ]] && echo
if [ "$1" == "ERR" ]; then
	# This is a critical error, game over.
	echo "  ERROR: ${2#n}"
	exit 1
elif [ "$1" == "WRN" ]; then
	# This is only a warning, script continues but may not work fully.
	echo "  WARNING: ${2#n}"
fi
}

#----------------------------------Do_Update-----------------------------------#
Do_Update ()
{
# Do_Update <Filename> <MD5 String>
# This function downloads and installs the update.
echo -n "Downloading $1..."
# Download URL is based on global variables plus given filename.
wget $BASEURL$APPNAME/$1 -P /tmp -q || \
	ErrorMsg ERR "nUnable to download update! Please try again later."
echo "OK!"

# Extract archive and then delete it
echo -n "Extracting $1..."
tar xf /tmp/$1 && rm /tmp/$1 || \
	ErrorMsg ERR "nThere was an error extracting the update!"
echo "OK!"

echo -n "Verifying file integrity..."
if [ "$(md5sum $APPNAME*.new)" != "$2" ]; then
	rm $APPNAME*.new
	ErrorMsg ERR "nUpdate failed MD5 check! Please try again later."
else
	# If MD5 passes, we move invoked script to .old and move the .new
	# into it's place. This will work even if user has renamed the script
        # to something else.
	echo "OK!"
	echo -n "Installing..."
	mv $0 $0.old &&	mv $APPNAME*.new $0 || \
		ErrorMsg ERR "nThere was an error installing the update!"
	echo "OK!"
	echo
	echo "##################################"
	echo "# Update installed successfully! #"
	echo "##################################"
	echo
	echo "Old version saved as $0.old."
	# Configuration is not copied over, maybe in future version?
	echo "Configuration was NOT copied, please do so manually."
	exit 10
fi
}

#----------------------------------Chk_Update----------------------------------#
Chk_Update ()
{
# Chk_Update <Action>
# Checks for update, but does not actually make changes to system.
# Relies on global variables "BASEURL" and "APPNAME", Argument determines what
# action it will take:
# 0 - Check only
# 1 - Prompt for update
# 2 - Automatically install update
[ $1 -eq 1 ] && echo -n "Downloading update information..."
wget $BASEURL$APPNAME/current.txt -q -O /tmp/$APPNAME-current.txt || \
	ErrorMsg ERR "nUnable to contact update server! Please try again later."
[ $1 -eq 1 ] && echo "OK!"

# This reads the file into the variables and then removes file, no need to
# leave it laying around.
exec 6<&0   
exec < /tmp/$APPNAME-current.txt
read CAND_VER
read CAND_FILE
read CAND_MD5
# Very important, close file descriptor or else user input won't work.
exec 0<&6 6<&-
rm /tmp/$APPNAME-current.txt

if [[ "$VER" == "$CAND_VER" ]]; then
	[ $1 -eq 1 ] && echo "You are running the latest version of $APPNAME."
	return 10
elif [[ "$VER" < "$CAND_VER" ]]; then
	if [ $1 -eq 1 ]; then
		echo "An update is available!"
		echo 
		echo "Installed version: $VER"
		echo "Candidate version: $CAND_VER"
		echo
		read -p "Update? (y/n) "
		if [ "$REPLY" = "y" -o "$REPLY" = "Y" ]; then
			echo "Updating..."
			# MD5 needs quotes or else it chops off filename.
			Do_Update $CAND_FILE "$CAND_MD5"
		else
			echo "Update canceled, exiting."
			exit 13
		fi
	elif [ $1 -eq 2 ]; then
		Do_Update $CAND_FILE "$CAND_MD5"
	else 
		return 11
	fi
else
	[ $1 -eq 1 ] && echo "You are running a development version!"
	return 12
fi
}

#-----------------------------Execution starts here----------------------------#
echo "Experimental Net_Update Engine - Version: $VER"

case "$1" in
'auto')
	echo "Automatically updating to latest version available..."
	Chk_Update 2
;;
'check')
	echo "Now checking for a new version, please wait..."
	Chk_Update 0
	
	case "$?" in
	'10')
		echo "You are running the latest version of $APPNAME!"
	;;
	'11')
		echo "There is an update available!"
	;;
	'12')
		echo "You are running a development version!"
	;;
	*)
		ErrorMsg ERR "An unknown error has occurred with the update!"
	;;
	esac
;;
'copy')
	echo -n "Now duplicating $0 for backup purposes"
	for ((i=1;i<=5;i+=1)); do
		cp $0 ./$0.$i
		echo -n "."
	done
	echo "Done."
;;
'update')
	echo "Now checking for new version, please wait..."
	Chk_Update 1
;;
'help')
	clear
	echo "This is an experimental build of net_update, a system to update"
	echo "Bash scripts over the Internet/LAN. It was written for use with"
	echo "the planned 2600 publication of linux_ics, but can be used in any"
	echo "script due to it's modular nature."
	echo ""
	echo "Available arguments as of version $VER are as follows:"
	echo ""
	echo "auto   - Automatically perform update to latest version"
	echo "update - Initiate an update"
	echo "copy   - Duplicates net_update, for testing"
	echo "check  - Just check for update, don't do anything"
	echo "help   - What you are reading now"
;;
*)
	echo "usage: $0 auto|check|copy|update|help"
esac
#EOF
