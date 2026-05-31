#!/bin/bash
set -euo pipefail

cd osboot

for f in bzImage single.gz multi.gz farewell.iso; do
    if [ ! -f "$f" ]; then
        echo "Missing $f"
        echo "Build all outputs first."
        exit 1
    fi
done

TIMESTAMP="$(date +"%d%m%Y-%H%M%S")"
ZIPNAME="farewell_backup_${TIMESTAMP}.zip"

zip -9 "$ZIPNAME" bzImage single.gz multi.gz farewell.iso

echo "[+] Backup created: osboot/$ZIPNAME"
