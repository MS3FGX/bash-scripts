#!/bin/sh
# Hackish way to set system time to GPS PPS

# Pre-fetch date info
DATE="$(date +%m%d)"
YEAR="$(date +%y)"

# Pause and return UTC time string as close to PPS as possible:
UTC="$(awk -F, '/\$GPGGA/ {print $2; exit}' /dev/rfcomm0 | cut -c 1-6)"
TIME="$(echo $UTC | cut -c 1-4)"
SECONDS="$(echo $UTC | cut -c 5-6)"

# Put it back together and set the time
date -u $DATE$TIME$YEAR.$SECONDS
