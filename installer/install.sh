#!/bin/busybox sh
# Compatibility wrapper — prefer /bin/hut-install

exec /bin/hut-install "$@"
