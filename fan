#!/bin/sh
if [ "$#" -eq "0" ]; then
    cat /proc/acpi/ibm/fan
elif [ "$#" -eq "1" ]; then
    echo level $@ | sudo tee /proc/acpi/ibm/fan
else
    echo $@ | sudo tee /proc/acpi/ibm/fan
fi

