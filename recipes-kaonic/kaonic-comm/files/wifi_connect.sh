#!/bin/sh

set -eu

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <ssid> <passphrase>" >&2
    exit 1
fi

exec /usr/bin/kaonic-wifi-mode sta "$1" "$2"
