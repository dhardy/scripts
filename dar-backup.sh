#!/bin/sh
# What: create a backup using dar
# How: run from directory to backup, first argument should be destination for backups
# Author: Diggory Hardy

# WARNING: this is still experimental (I am not familiar with dar)

# TODO: exclude rules (e.g. .o, .cache, .ccache)

if [ "$#" -ne "1" ]; then
    echo "Usage: $0 DEST"
    echo "where DEST is the location to store backups, e.g."
    echo "/run/media/dhardy/backup/dar"
    exit 1
fi

die(){
    for p in "$@"; do
        echo "$p" >&2
    done
    exit 1
}

DAR=$(which dar)
if [ ! -x "$DAR" ]; then
    die "Command not found: dar"
fi

DEST="$1"
NOW="$(date -u -Ihours)"
DEST_NOW="${DEST}/$NOW"
DEST_LATEST="${DEST}/latest"

if [ -e "$DEST_NOW" ]; then
    die "Stopping because destination already exists:" "$DEST_NOW"
fi
mkdir -p "$DEST_NOW" || die "Error creating $DEST_NOW"
mkdir -p "$DEST_LATEST" || die "Error creating $DEST_LATEST"
echo "Backup destination: $DEST_NOW"

link_latest(){
    # $1: local name of backup minus extension
    LATEST="DEST_LATEST/$1.dar"
    if [ -L "LATEST" ]; then
        rm -f "$LATEST" || return 1
    fi
    ln -s "../$NOW/$1.dar" "$LATEST" || return 1
}

backup_dir(){
    echo "Backing up $1 ..." &&\
    $DAR -c "$DEST_NOW/$1" $1 &&\
    link_latest "$1" &&\
    echo "Done backing up $1"
}

MISC_FILES=""
for f in $(ls -A); do
    if [ -d "$f" ]; then
        backup_dir "$f"
    else
        MISC_FILES="$MISC_FILES $f"
    fi
done

N=0
MISC_DEST="$DEST_NOW/misc"
while [ -e "$MISC_DEST.dar" ]; do
    let N=N+1
    MISC_DEST="$DEST_NOW/misc-$N"
done
echo "Backing up miscellaneous files to: $MISC_DEST"
echo "Files:$MISC_FILES"
# FIXME This will probably fail on files with spaces in the name:
$DAR -c "$MISC_DEST" $MISC_FILES &&\
link_latest "$MISC_DEST"
echo "Done backing up miscellaneous files."
echo "Backup finished. Links to the latest backup can be found in: $DEST_LATEST"
