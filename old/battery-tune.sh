#!/bin/bash

# This is a collection of notes about various laptop power-tuning I've found on
# the internet and tested on a lenovo T410.

# Booting with the pcie_aspm=force kernel option helps:
# Force ASPM:
# 13.4W idle, 34W glxgears
# Without:
# 14.6W idle, 35W glxgears

# Wifi appears to use about 1.8W
# Wifi power saving (enabled by powertop) saves perhaps half a watt

# Screen uses perhaps 4.5W more on full brightness than on minimum

# These tweaks can only be done by root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Setting power control of all devices to auto possibly saves about 0.8W (need
# to do a better test):
# (Note that this appears to disable external mice until you re-plug them in.)
for i in $(find /sys/devices/pci* -wholename "/sys/devices/pci*/power/control"); do
    if [[ "$(cat $i)" == "on" ]]; then
        echo "auto" > $i;
    fi;
done;


# Disabling nmi_watchdog has no obvious effect:
# echo 0 > /proc/sys/kernel/nmi_watchdog

# Turning off USB (instead of leaving auto) appears to have no effect:
# (I seem to have lost the commands to do this. Never mind.)

# don't usually need eth0 while on battery
rmmod e1000e
# disable bluetooth
/etc/init.d/bluetooth stop
