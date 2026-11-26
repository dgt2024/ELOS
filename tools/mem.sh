#!/usr/bin/env bash
set -euo pipefail

if [ $# -eq 0 ]; then exit 1; fi

SOCK="/tmp/qemu-mon.sock"
CMD=$(printf "%s " "$@")

while true; do
    OUT=$(printf "%s\r\n" "$CMD" | socat -t 0.05 - "UNIX-CONNECT:$SOCK" | tail -n +3)
    printf "\033[H\033[J> %s\n%s\n" "$CMD" "$OUT"
    sleep 0.1
done
