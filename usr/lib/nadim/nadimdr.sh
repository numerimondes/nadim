#!/bin/bash
# nadimdr.sh - Nadim with elevated privileges
# License: GPL-3.0
[ ! -f /usr/lib/nadim/nadim.sh ] && echo "Error: Nadim not installed" && exit 1
[ "$(id -u)" -ne 0 ] && echo "Elevating privileges..." && exec sudo "$0" "$@"
exec /usr/lib/nadim/nadim.sh "$@"
