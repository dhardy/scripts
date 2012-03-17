#!/bin/sh
# Script for managing thinkpad batteries.
# When run with no parameters: shows the thresholds at which charging starts
# and stops.
# When run with two parameters (in range 0-100): sets thresholds (run as root).

# old hack required:
#lsmod | grep thinkpad_ec >/dev/null || insmod /lib/modules/2.6.28-13-generic/extra/thinkpad_ec.ko force_io=1
# Should be:
#modprobe -d /lib/modules/`uname -r`/extra thinkpad_ec  force_io=1

# Broken if?
# hdaps can't be loaded:
#TEST_SMAPI="lsmod | grep tp_smapi"
#if [ -z $($TEST_SMAPI) ]
#then
#	rmmod hdaps
#	modprobe tp_smapi
#	modprobe hdaps
#fi

if [ $# -eq 0 ]
then
	cat /sys/devices/platform/smapi/BAT0/start_charge_thresh
	cat /sys/devices/platform/smapi/BAT0/stop_charge_thresh
elif [ $# -eq 2 ]
then
	echo -n $1 > /sys/devices/platform/smapi/BAT0/start_charge_thresh
	echo -n $2 > /sys/devices/platform/smapi/BAT0/stop_charge_thresh
else
	echo "Usage: $0 start stop"
	echo "Sets battery charging starting and stopping percentages"
	exit 1
fi
