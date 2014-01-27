#!/bin/sh
# Lists files in trash by age

TEMP=$(mktemp)
TRASH="$HOME/.local/share/Trash"
for f in $TRASH/info/*; do echo "$(grep Dele "$f" | cut -d= -f2)	$(du -hs "$TRASH/files/$(basename "$f" .trashinfo)")" >> "$TEMP"; done
cat "$TEMP" | sort | less
rm -f "$TEMP"
