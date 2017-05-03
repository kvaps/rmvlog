#!/bin/bash
set -x

LOG_DIR=/var/log/one
LOG_NAME='[0-9]*.log'
SERVER=localhost
NEW_LOG_DIR=/var/log/one2

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
