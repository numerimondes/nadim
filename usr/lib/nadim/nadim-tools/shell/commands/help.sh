#!/bin/bash
# help.sh - Help command for shell
# License: GPL-3.0
source /usr/lib/nadim/platform/environment.sh
source /usr/lib/nadim/platform/helpers.sh
source /usr/lib/nadim/nadim-tools/shell/config.sh
echo -e "${BOLD}Tool: $TOOL_NAME${RESET}"
echo "Description: $TOOL_DESCRIPTION"
echo -e "\n${BOLD}Usage:${RESET}"
echo "  nadim shell [interactive]"
echo "  nsh"
echo -e "\n${BOLD}Available Commands:${RESET}"
echo "  interactive - Enter interactive shell mode"
echo "  help        - Display this help message"
exit 0
