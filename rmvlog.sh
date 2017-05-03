#!/bin/bash

LOG_DIR="$(dirname "$1")"
LOG_NAME="$(basename "$1")"
SERVER="$(echo $2 | grep -oP "^.*(?=:)")"
NEW_LOG_DIR="$(echo $2 | grep -oP "[^:]*$")"

SERVER="${SERVER:-localhost}"
NEW_LOG_DIR=${NEW_LOG_DIR%/}

if [ -z "$NEW_LOG_DIR" ] || [ ! -z "$3" ] || [ -f "$1" ]; then
    echo "USAGE: $(basename "$0") '/path/to/log/[0-9]*.log' 'logserver:/path/to/log'"
    exit 1
fi

cd "$LOG_DIR"

while read LOG_FILE; do
    if [ -f "$LOG_FILE.sync" ]; then
        mv "$LOG_FILE" "$LOG_FILE.sync"
    else
        cat "$LOG_FILE" >> "$LOG_FILE.sync" && rm "$LOG_FILE"
    fi
done < <(eval find . -maxdepth 1 -type f -name \'$LOG_NAME\' ! -empty)

while read SYNC_FILE; do
    rm "$SYNC_FILE"
done < <(eval find . -maxdepth 1 -type f -name \'$LOG_NAME.sync\' ! -empty -printf \'%P\\n\' | tar -czT - -f - | ssh $SERVER "tar -xzf - --to-command='sh -c \"cat >> \\\"${NEW_LOG_DIR}/\$(basename \$TAR_FILENAME .sync)\\\" && echo \$TAR_FILENAME\"'")
