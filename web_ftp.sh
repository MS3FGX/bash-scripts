#!/bin/bash
#
# Script to generate a web page of links for files served over FTP.

# Lets play this one safe...
set -e

# Some versions of "echo" don't need the -e option
ECHO_CMD="echo -e"

# Parts of link:
LINK_ROOT="<td><a href=\042ftp://ftp.digifail.com/"
LINK_END="\042>"

# No need to edit past this point

html_head ()
{
cat << EOF > $OUTFILE
<html>
<meta http-equiv="Pragma" content="no-cache">
<meta http-equiv="Expires" content="-1">
<meta http-equiv="CACHE-CONTROL" content="NO-CACHE">
<head>
<link href="/filelist.css" type="text/css" rel="stylesheet" />
</head>
<body>
<table border="1" bordercolor="white" cellpadding="5" cellspacing="5" width="100%">
<tr>
<th>Filename</th>
<th>MD5</th>
<th>Size</th>
<th>Date</th>
</tr>
EOF
}

html_close ()
{
echo "</table>" >> $OUTFILE
echo "</body>" >> $OUTFILE
echo "</html>" >> $OUTFILE
}

check_dir ()
{
	# Make sure we have a target
	[ "$1" = "" ] && echo "Must give target!" && exit
	
	# Check what we are dealing with
	case "$1" in 
	*slackware*)
		LINK_DIR="slackware/packages/"
	;;
	*software*)
		LINK_DIR="downloads/software/"
		# Sort software by time, not alpha. Puts newer versions on top
		LSARG="-t"
	;;
	*text*)
		# May have subdirectories in the future
		LINK_DIR="downloads/"
	;;
	esac

	# Change to given directory
	cd $1
	
	# Put our current directory into variable
	CWD=$(basename `pwd`)
	
	# Complete URL
	LINK_DIR=$LINK_DIR$CWD"/"
	
	# File to output
	OUTFILE="/tmp/web/$CWD.html"
	
	# Delete the old file if it exists
	rm -f $OUTFILE 
}

make_meta ()
{
echo -n "Creating meta files..."
# Start HTML file
html_head

for FILENAME in `ls -l $LSARG | grep ^- | awk '{print $9}'`
	do
		# Print start character for table row
		echo "<tr>" >> $OUTFILE
		# Check if hidden meta file exists, create if it doesn't
		if [ ! -f ".$FILENAME.meta" ]; then
			# Create meta file
			touch ".$FILENAME.meta"
			# Put MD5 into it
			md5sum $FILENAME | awk '{print $1}' >> "./.$FILENAME.meta"
			# Size, bytes if smaller than 4K
			FILESIZE=`du -h $FILENAME | awk '{print $1}'`
			if [ "$FILESIZE" = "4.0K" ]; then
				echo "`du -b $FILENAME | awk '{print $1}'`B" >> "./.$FILENAME.meta"
			else
				echo $FILESIZE >> "./.$FILENAME.meta"
			fi
			# Creation date
			ls -l --time-style=long-iso $FILENAME | awk '{print $6}' >> "./.$FILENAME.meta"
		fi
		# Write out the link and filename
		$ECHO_CMD $LINK_ROOT$LINK_DIR$FILENAME$LINK_END"$FILENAME</a></td>" >> $OUTFILE
		# Pull data out of meta		
		for LINENUM in 1 2 3
		do
			echo "<td>"$(awk 'NR=='$LINENUM'' ./.$FILENAME.meta)"</td>" >> $OUTFILE
		done		
		# Close table
		echo "</tr>" >> $OUTFILE
	done
# Close up HTML file
html_close
echo "OK"
}

remove_old ()
{
	echo -n "Removing old meta files..."
	rm -f ./.*meta
	echo "OK"
}

case "$1" in
'update')
	check_dir $2
	make_meta
;;
'rebuild')
	check_dir $2
	remove_old
	make_meta
;;
'remove')
	remove_old
;;
*)
	echo "$0 [update|rebuild|remove] PATH"
;;
esac
# EOF
