#!/usr/bin/env bash

# Needs to be run with sudo
if [ "$EUID" -ne 0 ]; then
    echo "This script needs to be run with sudo or as a root user"
    exit 1
fi
LOCALSNAPSHOTSDIR="/home/SNAPSHOT"
EXTERNALSNAPSHOTSDIR="/mnt/sn550"
USER=dhardy

LATEST_HOME=(`ls -d $LOCALSNAPSHOTSDIR/$USER-* | sort | tail -c 11`)
LATEST_HOME_EXTERNAL=(`ls -d $EXTERNALSNAPSHOTSDIR/$USER-* | sort | tail -c 11`)
TODAY=`date +%Y-%m-%d`

# make local snapshot
if test -d "$LOCALSNAPSHOTSDIR"; then
    echo "Using directory $LOCALSNAPSHOTSDIR for local snapshots."
    if [[ "$LATEST_HOME" != "$TODAY" ]]; then
        echo "Today is $TODAY and latest home backup was $LATEST_HOME doing new snapshot"
        btrfs subvolume snapshot -r /home/$USER $LOCALSNAPSHOTSDIR/$USER-$TODAY
    else
        echo "Todays backup already done"
    fi
fi

# make an external backup of the snapshot
# destination drive needs to be formatted as BTRFS !
if test -d "$EXTERNALSNAPSHOTSDIR"; then
    echo "using directory $EXTERNALSNAPSHOTSDIR for external backup."
    if [[ "$LATEST_HOME_EXTERNAL" != "$TODAY" ]]; then
        echo "Today is $TODAY and latest external backup is $LATEST_HOME_EXTERNAL copying data to external drive"
        # Update using latest external backup-date as reference to do the differential backup against
        btrfs send -p $LOCALSNAPSHOTSDIR/$USER-$LATEST_HOME_EXTERNAL $LOCALSNAPSHOTSDIR/$USER-$TODAY | btrfs receive $EXTERNALSNAPSHOTSDIR
    else
        if test -f "$EXTERNALSNAPSHOTSDIR/$USER-$TODAY"; then
            echo "External backup already up to date"
        else
            echo "Earlier versions not found, creating the first external backup to $EXTERNALSNAPSHOTSDIR"
            btrfs send $LOCALSNAPSHOTSDIR/$USER-$TODAY | btrfs receive $EXTERNALSNAPSHOTSDIR
        fi
    fi
else
    echo "External drive not found, is it mounted?"
fi
