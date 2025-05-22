#!/bin/bash
# help.sh - Help command for tools
# License: GPL-3.0
source /usr/lib/nadim/platform/environment.sh
source /usr/lib/nadim/platform/helpers.sh
source /usr/lib/nadim/nadim-tools/tools/config.sh
echo -e "${BOLD}Tool: $TOOL_NAME${RESET}"
echo "Description: $TOOL_DESCRIPTION"
echo -e "\n${BOLD}Usage:${RESET}"
echo "  nadim tools <command>"
echo -e "\n${BOLD}Available Commands:${RESET}"
echo "  create - Create a new tool"
echo "  update - Update an existing tool"
echo "  delete - Delete a tool"
echo "  help   - Display this help message"
exit 0
