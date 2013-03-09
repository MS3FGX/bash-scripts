#!/bin/sh

# 2Pass.sh
APPNAME="2Pass"
VER="1.0"
# Simple script to do a two pass XviD encode on given file. Can also encode all
# files in current directory.

# Set bitrate for final video
RATE=6000

#------------------------------------------------------------------------------#

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

VerifyCmd ()
{
# VerifyCmd <Output Bool> <Command>
# Checks to see if given command exists, optional output.
[ $1 -eq 1 ] && echo -n "Checking for $2: "
if which $2 > /dev/null 2>&1; then
	[ $1 -eq 1 ] && echo "OK"
	return 0
else
	[ $1 -eq 1 ] && echo "FAILED"
	return 1
fi
}

FirstPass ()
{
# FirstPass <Filename>
# Preforms first pass scan on file <Filename>
if [ -f ./divx2pass.log ]; then
	echo "An existing first pass log has been found!"
	echo "Skipping to second pass!"
	return
else
	echo "Starting first pass on $1..."
	mencoder "$1" -oac mp3lame -ovc xvid -xvidencopts pass=1 -o /dev/null
	[ $? == 1 ] && ErrorMsg ERR "First pass failed!"
fi
}

SecondPass ()
{
# SecondPass <Filename>
# Preforms second pass encode on file <Filename>
echo "Starting second pass on $1..."
[ -f ./divx2pass.log ] || ErrorMsg ERR "No first pass log found!"
# Determine original file extension
ORIGEXT=`echo "$1" | awk -F . '{print $NF}'`
if [ $ORIGEXT == "avi" ]; then
	NEWEXT="avi.new"
else
	NEWEXT="avi"
fi
mencoder "$1" -oac mp3lame -ovc xvid -xvidencopts pass=2:bitrate=$RATE -o "${1%.*}.$NEWEXT"
[ $? == 1 ] && ErrorMsg ERR "Second pass failed!"
if [ -f ./divx2pass.log ]; then # Do I need to do this?
	rm ./divx2pass.log
fi
}

#------------------------------------------------------------------------------#

case "$1" in
'all')

;;
'single')
echo "Starting $APPNAME $VER in single file mode."
# Did the user give us a filename?
[ "$2" == "" ] && ErrorMsg ERR "You have to give a file name!"
# Does the file exist?
echo -n "Checking source file..."
[ -f "$2" ] || ErrorMsg ERR "nFile does not appear to exist!"
echo "OK"
FirstPass "$2"
SecondPass "$2"
echo "Encoding of $2 complete!"
;;
'multi')
echo "Starting $APPNAME $VER in multi file mode."
ls ./* | while read I; do
	echo "Starting encode of "$I""
	FirstPass "$I"
	SecondPass "$I"
	echo "Encoding of $I complete!"
done
echo "Encoding complete for all files!"
;;
'help')
echo "This is $APPNAME, a script to perform a 2 pass XviD encode on either a"
echo "single or multiple video files. This is designed so that an entire"
echo "directory of files can be converted without human intervention, as in"
echo "the case with converting an entire series or season of a show."
echo
echo "The available arguments as of version $VER are as follows:"
echo "single - Converts single file, must give valid source filename"
echo "multi  - Converts all files in current directory (video or not)"
echo "help   - What you are reading now"
;;
*)
echo "$APPNAME Version $VER"
echo "usage: $0 single|multi|help"
esac
# EOF
