#!/bin/bash
# global-help.sh - Global help listing all Nadim tools and their commands
# License: GPL-3.0

source /usr/lib/nadim/platform/environment.sh
source /usr/lib/nadim/platform/helpers.sh

launch_header

BLUE="${BLUE:-\e[34m}"
GREEN="${GREEN:-\e[32m}"
RESET="${RESET:-\e[0m}"

echo -e "${BLUE}Nadim Tools Global Help${RESET}\n"

for tool_dir in /usr/lib/nadim/nadim-tools/*/; do
    [ -f "$tool_dir/config.sh" ] || continue
    source "$tool_dir/config.sh"

    cmds=()
    for cmd in "$tool_dir/commands"/*.sh; do
        [ -f "$cmd" ] || continue

        # Skip commands marked with HIDE_FROM_HELP=1
        if grep -q "^HIDE_FROM_HELP=1" "$cmd"; then
            continue
        fi

        cmd_name=$(basename "$cmd" .sh)

        # Exclude 'help' command itself
        if [ "$cmd_name" = "help" ]; then
            continue
        fi

        cmds+=("$cmd_name")
    done

    # Skip tool if no commands available
    if [ ${#cmds[@]} -eq 0 ]; then
        continue
    fi

    echo -e "${BLUE}Tool: $TOOL_NAME - $TOOL_DESCRIPTION${RESET}"

    # Join commands with comma + space, commands in green
    cmds_str=""
    for c in "${cmds[@]}"; do
        if [ -n "$cmds_str" ]; then
            cmds_str+=", "
        fi
        cmds_str+="${GREEN}${c}${RESET}"
    done

    echo -e "Available Commands: ${cmds_str}"
    echo "To know more, do: nadim $TOOL_NAME help"
    echo
done

exit 0
# Examples (commented out)
# echo -e "\nExamples:"
# echo " nadim tools create my-tool \"My custom tool\" mt"
# echo " nadim tools update my-tool \"Updated description\""
# echo " nadim tools delete my-tool"
