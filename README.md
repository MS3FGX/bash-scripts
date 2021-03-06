![Terminal](http://www.digifail.com/images/misc/github/term_header.gif "WUB WUB WUB")

Bash Scripts
==============

The following Bash scripts were developed with an eye towards reliability and functionality. These are the ones which I consider proper software releases, rather than just one-off hacks.

linux_ics.sh
--------------

A complete tool to share an Internet connection from your Linux box to other devices over WiFi or Ethernet. When properly configured, it will setup all interfaces and even provide DHCP leases for connected devices.

net_update.sh
--------------

This is a prototype for a mechanism to update Bash scripts over the Internet. It can check for new releases, download/verify them, and install them over the original script. While I never actually implemented this into my other scripts, the concept seems sound enough.

web_ftp.sh
--------------

This script is used on the server which runs www.digifail.com to generate the HTML files for all "Download" listings. By generating a metadata file for everything in a given directory, it can combine those up into an HTML file which contains a table listing all the relevant file info and download link.

Miscellaneous Bash Scripts
==============

The rest of the scripts are ones I've written over the years for various projects or tasks. In general, these are not terribly well tested or even thought out, but they more or less seem to work. Perhaps others will have a use for them.

- 2Pass.sh - Performs 2 pass Xvid encode on video files.
- archive.sh - Used to compress all files in working directory.
- gpstime.sh - Hack to set system time from Bluetooth GPS device.

License
==============

These scripts are being released with a standard 3-clause BSD license. Please see "LICENSE" for complete details.
