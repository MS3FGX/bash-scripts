#!/bin/bash
# 
# linux_ics.sh
VER="0.9.1"
#
# A script to bridge two interfaces and perform NAT under Linux. Can be used
# to share an Internet connection to client devices.
#
#---------------------------------License--------------------------------------#
#
# Copyright 2010, Tom Nardi (MS3FGX@gmail.com)
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. The name of the author may not be used to endorse or promote products
#    derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#-------------------------User Configuration Section---------------------------#

# DHCP Configuration:

# Disable/enable DHCP server (0 = Disable, 1 = Enable)
#    Enable this if you want to automatically configure the clients with
#    correct TCP/IP information. The default is 1, Enable.
USEDHCP=1

# DHCP configuration file
#    If you want DHCP support, you need this file. The default is "DHCP.conf",
#    located in /tmp. You can create this file by calling linux_ics with the
#    "dhcpconfig" command.
CONFFILE=/tmp/DHCP.conf

# Hardware Configuration:

# Source Interface
#    This is the interface connected to the main network or Internet. This can
#    be any interface on your machine. The default is your primary Ethernet
#    card, eth0.
SRC="eth0"

# Destination Interface
#    This is the device that will be used to share the connection to the
#    clients, normally an Ethernet card or a wireless device. The default is
#    your secondary Ethernet card, eth1.
DST="eth1"

# Destination Type (0 = Standard, 1 = WiFi)
#    This option determines if linux_ics attempts to configure the destination
#    interface as a wireless device. If you leave this disabled you can still
#    use a wireless destination interface, but you will need to configure it
#    outside of this script. The default is type 0, Standard.
DSTTYPE=0

# Source DHCP (0 = Disable, 1 = Enable)
#    Enable this if you want the source interface to be configured with DHCP
#    before the script runs. Usually you don't need to do this, so the default
#    is 0, Disable.
SRCUP=0

# DHCP hostname (only used if above is enabled)
#    If you want to configure your source interface with DHCP, this will be the
#    hostname it sends to the DHCP server. Useful if you want to see this
#    machine in your router's DHCP logs.
DHCPHOST="LINUX_ICS"

# Destination IP
#    This is the IP address given to the destination interface. The default
#    should work in most home networks.
IPADDR="192.168.2.1"

# WiFi Configuration:

# Wireless Mode
#    This determines which mode your card will try and run in. Can be either
#    "Master" or "Ad-Hoc". Since Ad-Hoc is much more likely to work, that is
#    the default.
WIFIMODE="Ad-Hoc"

# SSID
#    The name that your new wireless network will go by. If you don't see this
#    come up when you are searching for an AP, something is probably wrong.
SSID="LINUX_AP"

# Channel
#    6 should be a safe default, but if you get interference, you might want
#    to change it to something else.
CHANNEL=6

#------------------------No need to edit past this line------------------------#

# Values for tweaking:

# DHCP Timeout
#    How long to wait for DHCP lease on source interface.
DHCPTIME=20

# WiFi Rate
#    Data rate for wireless card.
RATE="Auto"

#---------------------------------Functions------------------------------------#

ErrorMsg ()
{
# ErrorMsg  
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
# VerifyCmd  
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

Config_SRC ()
{
# Brings up SRC interface with DHCP, if enabled
echo -n "Running DHCP on $SRC..."
# Check if PID file exists, hopefully this catches all distros
if [ -f /var/run/dhcpcd-$SRC.pid -o -f /etc/dhcpc/dhcpcd-$SRC.pid ]; then
	# Don't run dhcpcd again on this interface
	ErrorMsg WRN "Interface already appears to be configured!"
else
	dhcpcd -t $DHCPTIME -d -h $DHCPHOST $SRC 2>/dev/null || \
		ErrorMsg ERR "DHCP configuration for $SRC failed!"
	echo "OK!"
fi
}

Config_DST ()
{
# ConfigDST 
# Set IP for destination interface, optionally configure WiFi.
echo -n "Assigning TCP/IP address $IPADDR to $DST..."
ifconfig $DST up $IPADDR 2>/dev/null || \
	ErrorMsg ERR "Unable to bring up TCP/IP on $DST! Wrong device?"
echo "OK!"

# Configure hardware if called with WiFi Bool on.
if [ $1 -eq 1 ]; then
	echo "Configuring $DST..."
	echo "    +---------------------+"
	# Set mode
	if iwconfig $DST mode $MODE > /dev/null 2>&1; then
		echo "    | Mode    | $MODE"
		# Set SSID
		iwconfig $DST essid $SSID
		echo "    | SSID    | $SSID"
		# Set channel
		if iwconfig $DST channel $CHANNEL > /dev/null 2>&1; then
			echo "    | Channel | $CHANNEL"
		else
			# Show a warning if card failed to change channels
			ErrorMsg WRN "Failed to change channel on $DST!" 
		fi
		# Set data rate
		if iwconfig $DST rate $RATE > /dev/null 2>&1; then
			echo "    | Rate    | $RATE"
		else
			# Show a warning if card failed to change rate
			ErrorMsg WRN "Failed to change data rate on $DST!"
		fi
		echo "    +---------------------+"
	else
		# Show an error if card failed to switch modes
		ErrorMsg ERR "$DST does not support this operating mode!" 
	fi
fi
}

Start_NAT ()
{
# Enable NAT through iptables
echo -n "Setting up Network Address Translation..."
iptables -t nat -A POSTROUTING -o $SRC -j MASQUERADE && \
iptables -A FORWARD -i $DST -j ACCEPT || \
	ErrorMsg ERR "There has been an error configuring iptables!"
echo 1 > /proc/sys/net/ipv4/ip_forward || \
	ErrorMsg ERR "Unable to communicate with the /proc filesystem!"
echo "OK!"
}

Start_DHCP ()
{
# Configure and start the DHCP server if it has been enabled by the user
echo -n "Starting DHCP server..."
# Make sure the server isn't already running
if [ -f /var/run/dhcpd.pid ]; then
	ErrorMsg WRN "dhcpd is already running! Skipping,,,"
else
	# Start dhcpd with DST interface and config file
	dhcpd $DST -q -cf $CONFFILE || \
		ErrorMsg ERR "Failed to start DHCP server on $DST!"
	echo "OK!"
fi
}

Chk_System ()
{
#Chk_System 
# Tests to make sure we have all the proper tools. Errors are always displayed
# but status messages can be toggled.
VerifyCmd $1 ifconfig
[ $? -eq 1 ] && ErrorMsg ERR "ifconfig not found! Check your path variable."
VerifyCmd $1 iptables
[ $? -eq 1 ] && ErrorMsg ERR "iptables not found! Check your path variable."
# The following are optional, and only checked if enabled.
# For WiFi support
if [[ $DSTTYPE == 1 ]]; then
	VerifyCmd $1 iwconfig
	[ $? -eq 1 ] && \
	ErrorMsg ERR "iwconfig not found! Is wireless-tools installed?"
fi
# For DHCP client support
if [[ $SRCUP == 1 ]]; then
	VerifyCmd $1 dhcpcd
	[ $? -eq 1 ] && \
	ErrorMsg ERR "dhcpcd not found! Required for DHCP client support."
fi
# For DHCP server support
if [[ $USEDHCP == 1 ]]; then
	VerifyCmd $1 dhcpd
	[ $? -eq 1 ] && \
	ErrorMsg ERR "dhcpd not found! Required for DHCP server support."
	[ $1 -eq 1 ] && echo -n "Checking for DHCP configuration: "
	if [ -f $CONFFILE ]; then
		[ $1 -eq 1 ] && echo "OK!"
	else
		[ $1 -eq 1 ] &&	ErrorMsg ERR \
		"nDHCP configuration file not found! Try running 'dhcpconfig'."
	fi
fi
}

Chk_Device()
{
# Show selected interfaces and verify supported modes of wireless device
echo "Hardware Configuration"
echo "---------------------------------"
echo "Source Interface: $SRC"
echo "Destination Interface: $DST"
echo -n "Destination Type:"
if [[ $DSTTYPE = "0" ]]; then
	echo " Standard"
else
	echo " WiFi"
	echo -n "Checking for Master mode on $DST: "
	if iwconfig $DST mode Master > /dev/null 2>&1; then
		echo "Supported"
	else
		echo "Not Supported"
	fi
	echo -n "Checking for Ad-Hoc mode on $DST: "
	if iwconfig $DST mode Ad-Hoc > /dev/null 2>&1; then
		echo "Supported"
	else
		echo "Not Supported"
	fi
fi
}

Config_DHCP ()
{
# Writes a DHCP configuration file, adapted to user config
[ -f ${CONFFILE} ] && \
	ErrorMsg ERR "DHCP configuration file already exists!"
echo "Writing DHCP.conf file..."
DNS1="$(cat /etc/resolv.conf | grep nameserver | head -n 1)"
cat << EOF > $CONFFILE
# DHCP.conf
#
# Generated by $0 on `date "+%A %B %e, %Y"`
#
# This line defines the DNS servers the clients will use.
# The first is auto-generated, the second is a public server
option domain-name-servers ${DNS1#nameserver }, 4.2.2.2;

# We don't use this but dhcpd conplains if this line is not here
ddns-update-style none;   

# IP range for 50 clients
subnet ${IPADDR%.*}.0 netmask 255.255.255.0
{
        range ${IPADDR%.*}.100 ${IPADDR%.*}.150;
        option routers $IPADDR;
}
# EOF
EOF
}

#---------------------------Execution starts here------------------------------#

# Make sure the user is running with root-level permissions
if [ $UID -ne 0 ]; then
	echo "Sorry, you need to have root permissions to run this script."
	echo "Either login as root, or run this though sudo. If using sudo,"
	echo "make sure your PATH variable is correct."
	exit
fi

# Now that we got that out of the way, let's see what the user wants to do:
case $1 in
'start')
	echo "Starting linux_ics $VER..."
	# Sanity check before doing anything else
	Chk_System 0
	echo
	# Configure SRC, if user enabled it
	if [[ "$SRCUP" == "1" ]]; then
		Config_SRC
	else
		echo "Skipping $SRC configuration"
	fi
	# Configure DST, with WiFi if user enabled it
	if [[ "$DSTTYPE" == "1" ]]; then
		Config_DST 1
	else
		Config_DST 0
	fi
	# Interfaces are now up, let's start networking over them
	Start_NAT
	# Start DHCP server, if enabled
	if [[ "$USEDHCP" == "1" ]]; then
		Start_DHCP
	else
		echo "Skipping DHCP server configuration."
	fi
	# If we get this far, then everything should be working
	echo "linux_ics started successfully!"
	exit 0
;;
'stop')
	echo "Stopping linux_ics..."
	# Reset WiFi device to automatic, if necessary
	if [[ "$DSTTYPE" == "1" ]]; then
		echo -"Restoring $DST to sane defaults..."
		iwconfig $DST mode auto channel auto rate auto 2>/dev/null || \
			ErrorMsg WRN "Unable to reset $DST!"
		echo "OK!"
	fi
	# Close out DST
	echo "Shutting down $DST..."
	ifconfig $DST down 2>/dev/null || \
		ErrorMsg WRN "Unable to bring down $DST!"
	# Kill the DHCP server
	if [[ "$USEDHCP" == "1" ]]; then
		echo "Stopping DHCP server..."
		kill -s SIGTERM `cat /var/run/dhcpd.pid` || \
			ErrorMsg WRN "Unable to kill DHCP server!"
	fi
	# Stop NAT. This _should_ preserve any existing firewall config.
	echo "Stopping NAT..."
	iptables -F forward && iptables -t nat -F || \
		ErrorMsg WRN "Unable to stop NAT!"
	# Everything should be cleaned up now.
	echo "linux_ics stopped!"
;;
'test')
	Chk_Device
	echo 
	echo "Sanity Checks"
	echo "---------------------------------"
	# Call Chk_System with status messages enabled
	Chk_System 1
;;
'dhcpconfig')
	Config_DHCP
;;
'help')
echo "This is linux_ics, a script to configure a Linux computer for sharing"
echo "Internet and network access between two interfaces".
echo
echo "linux_ics can be used with conventional Ethernet network devices (the"
echo "default) or wireless devices (assuming your hardware supports it)."
echo
echo "The available arguments as of version $VER are as follows:"
echo "start      - Starts linux_ics"
echo "stop       - Stops linux_ics and returns devices to normal state"
echo "test       - Tests your hardware and software, shows debug information"
echo "dhcpconfig - Writes a DHCP configuration file, adapts to script settings"
echo "help       - What you are reading now"
;;
*)
echo "linux_ics Version: $VER"
echo "usage: $0 start|stop|test|dhcpconfig|help"
esac

# EOF
