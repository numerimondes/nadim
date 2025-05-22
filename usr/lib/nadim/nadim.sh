#!/bin/bash
# nadim.sh - Nadim Dolphin Rescue main script
# License: GPL-3.0

source /usr/lib/nadim/platform/environment.sh
source /usr/lib/nadim/platform/helpers.sh
source /usr/lib/nadim/platform/autoload.sh

# Check if Nadim is properly installed
[ ! -d "$NADIM_ROOT" ] && log_message "ERROR" "Nadim not installed at $NADIM_ROOT" && exit 1

# Verify dependencies
check_dependencies || log_message "WARNING" "Some dependencies missing"

# Handle special flags
case "$1" in
    --enable-fallback)
        echo "NADIM_FALLBACK_ENABLED=1" > "$NADIM_CONFIG_FILE"
        log_message "SUCCESS" "Fallback enabled"
        exit 0
        ;;
    --disable-fallback)
        echo "NADIM_FALLBACK_ENABLED=0" > "$NADIM_CONFIG_FILE"
        log_message "SUCCESS" "Fallback disabled"
        exit 0
        ;;
esac

# Save command to history and process it
save_command_to_history "$@"

# If no arguments provided, show help
if [ $# -eq 0 ]; then
    process_command "help" "help"
else
    process_command "$@"
fi

exit $?