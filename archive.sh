#!/bin/sh
#
# Script to scan a directory for files, and compress them if they haven't
# already been.

# Compression, gzip and bzip2 supported
COMP="bzip2"

# Delete files after compression (BE CAREFUL)
DELFILE="yes"

# Make sure we have a target
[ "$1" == "" ] && echo "Must give target!" && exit

# Determine compression type and extension
if [ "$COMP" == "gzip" ]; then
	COMPEXT="gz"
elif [ "$COMP" == "bzip2" ]; then
	COMPEXT="bz2"
else
	echo "Unsupported compression type!"
	exit
fi

# Create the list of files to work with
LIST=`find $1 -type f`

# Search for files
for i in $LIST;
do
	if [ `echo $i | awk -F . '{print $NF}'` != "$COMPEXT" ]; then
		echo -n "Compressing $i..."
		gzip -c9 $i > $i.$COMPEXT
		echo "OK!"
		[ "$DELFILE" == "yes" ] && rm -f $i
	fi
done
