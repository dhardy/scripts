#!/bin/sh
# What: sync all annexes including data
# How: $0 blue.ext  where 'blue.ext' is a remote known by each repository
# Assumption: remotes are configured; remotes do not have uncommitted data;
# remotes are bare (i.e. not necessary to update their working trees)
# Author: Diggory Hardy

if [ "$#" -lt "1" ]; then
    echo "Usage: $0 REMOTE [REPO] [REPO...]"
    exit 1
fi

REMOTE=$1
shift
if [ "$#" -gt "0" ]; then
    REPOS="$@"
else
    REPOS="/home/dhardy/annex /home/dhardy/pictures/photos /home/dhardy/swisstph/docs /home/dhardy/Documents"
fi

sync(){
    echo "Synching $1 ..." && \
    cd "$1" && \
    git remote show $REMOTE && \
    git annex add . --quiet && \
    git annex sync $REMOTE && \
    git annex copy --from $REMOTE --quiet && \
    git annex copy --to $REMOTE --quiet && \
    cd - && \
    echo "Successfully synchronised $1 with $REMOTE"
}

for repo in $REPOS; do
    if [ -d "$repo" ]; then
        sync "$repo"
    else
        echo "Skipping missing repository: $repo"
    fi
done
