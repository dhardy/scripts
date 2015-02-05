#!/bin/sh
# What: create a backup using dar. Rather than create a single backup archive it
# creates one for each directory of the current directory, plus an additional
# "misc" archive for files not in a subdirectory.
# How to use: run from directory to backup, first argument should be destination for backups
# Author: Diggory Hardy

# NOTE: this has had only a little testing so far, but all features do appear to work.


# ———  configuration  ———

# NOTE: you may with to change the include/exclude rules.
# See dar manual; not all rules are implemented here.

# This is a space-separated list of globs of file names to exclude.
EXCLUDE_FILES="*.o"

# This is a space-separated list of top-level files and directories to exclude from the backup.
EXCLUDE_TOP=".cache .ccache .bash_history .thumbnails games download .spring kdesrc"

# This is a space-separated list of globs of paths to exclude.
EXCLUDE_PATHS=".local/share/Steam .local/share/Trash .local/share/akonadi .local/share/baloo .kde/share/apps/nepomuk .Idea*/system"

# File globs not to compress
NO_COMPRESSION="*.gz *.bz2 *.zip *.png *.jpg *.jpeg"

# 0 or 1 : if set, backups are relative to the previous backup
RELATIVE_BACKUPS="1"

# Additional options. You can specify compression here, e.g. -zlzo:9 or -zgzip:1 .
# Disable the SECURITY WARNING which it seems is falsely triggered by git-annex
DAR_OPTS="-zlzo:9 --alter=secu"

# ———  end of configuration section  ———

# Add exclude rules. Warning: do not use -g the same way; we use it below to select what to back up.
for ef in $EXCLUDE_FILES; do
    DAR_OPTS="$DAR_OPTS -X $ef"
done
for ep in $EXCLUDE_PATHS; do
    DAR_OPTS="$DAR_OPTS -P $ep"
done
for nc in $NO_COMPRESSION; do
    DAR_OPTS="$DAR_OPTS -Z $nc"
done

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
NOW="$(date -Ihours)"
DEST_NOW="${DEST}/$NOW"
DEST_LATEST="${DEST}/latest"

if [ -e "$DEST_NOW" ]; then
    die "Stopping because destination already exists:" "$DEST_NOW"
fi
mkdir -p "$DEST_NOW" || die "Error creating $DEST_NOW"
mkdir -p "$DEST_LATEST" || die "Error creating $DEST_LATEST"
echo "Backup destination: $DEST_NOW"

# return 0 (true) if $1 is in EXCLUDE_TOP, otherwise 1 (false)
exclude_top(){
    for e in $EXCLUDE_TOP; do
        if [ "$1" = "$e" ]; then
            return 0    # match, return true
        fi
    done
    return 1    # no match, return false
}

link_latest(){
    # $1: local name of backup minus extension
    # FIXME This will probably fail on files with spaces in the name:
    for l in $DEST_LATEST/$1.*.dar; do
        rm -f "$l" || return 1
    done
    for l in $DEST_NOW/$1.*.dar; do
        ln -s "../$NOW/$(basename "$l")" "$DEST_LATEST/$(basename "$l")" || return 1
    done
}

backup_dir(){
    if [ "$RELATIVE_BACKUPS" -eq "1" -a -f "$DEST_LATEST/$1.1.dar" ]; then
        echo "Backing up $1 (relative mode) ..."
        OPTS="$DAR_OPTS -A $DEST_LATEST/$1"
    else
        echo "Backing up $1 (standalone backup) ..."
        OPTS="$DAR_OPTS"
    fi
    echo $DAR -c "$DEST_NOW/$1" $OPTS -g $1 &&\
    $DAR -c "$DEST_NOW/$1" $OPTS -g $1 &&\
    link_latest "$1" &&\
    echo "Done backing up $1"
    echo # extra new line
}

MISC_FILES=""
for f in $(ls -A); do
    if exclude_top $f; then
        echo "Excluding: $f"
    elif [ -d "$f" -a ! -L "$f" ]       # directory and not a link
    then
        backup_dir "$f" || echo "Error occurred; skipping: $f"
    else
        MISC_FILES="$MISC_FILES $f"
    fi
done

N=0
MISC_DEST="misc"
while [ -e "$DEST_NOW/$MISC_DEST.1.dar" ]; do
    let N=N+1
    MISC_DEST="misc-$N"
done
# FIXME This will probably fail on files with spaces in the name:
MISC_ARGS=""
for mf in $MISC_FILES; do
    MISC_ARGS="$MISC_ARGS -g $mf"
done
if [ "x$MISC_ARGS" != "x" ]; then
    echo "Backing up miscellaneous files to: $MISC_DEST"
    echo $DAR -c "$DEST_NOW/$MISC_DEST" $DAR_OPTS $MISC_ARGS &&\
    $DAR -c "$DEST_NOW/$MISC_DEST" $DAR_OPTS $MISC_ARGS &&\
    link_latest "$MISC_DEST"
    echo "Done backing up miscellaneous files."
fi

echo "Backup finished. Links to the latest backup can be found in: $DEST_LATEST"
