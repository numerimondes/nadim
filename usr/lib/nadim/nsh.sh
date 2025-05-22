#!/bin/bash
# nsh.sh - Nadim shell wrapper
# License: GPL-3.0
[ ! -f /usr/lib/nadim/nadim.sh ] && echo "Error: Nadim not installed" && exit 1
exec /usr/lib/nadim/nadim.sh shell interactive
