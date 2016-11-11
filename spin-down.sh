#!/bin/sh

for hd in $(ls /dev/sd[a-z])
do
    # continue if $hd is found in the output of df
    df | grep -q $hd && continue
    
    echo "Spinning down unmounted disk $hd"
    sudo hdparm -Y $hd
done
