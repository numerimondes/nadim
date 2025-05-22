#!/bin/bash
# delete.sh - Delete an existing Nadim tool
# License: GPL-3.0

source /usr/lib/nadim/platform/environment.sh
source /usr/lib/nadim/platform/helpers.sh
source /usr/lib/nadim/nadim-tools/tools/config.sh

delete_tool() {
    local tool_name="$1"
    
    # Interactive mode if no tool specified
    if [ -z "$tool_name" ]; then
        echo -n "Tool name to delete: "
        read tool_name
    fi
    
    local tool_dir="${NADIM_TOOLS_DIR}/${tool_name}"
    
    # Check if tool exists
    [ ! -d "$tool_dir" ] && log_message "ERROR" "Tool '$tool_name' doesn't exist" && return 1
    
    # Protect critical tools
    case "$tool_name" in
        help|tools|shell)
            log_message "ERROR" "Cannot delete core tool '$tool_name'" 
            return 1
            ;;
    esac
    
    # Check write permissions
    [ ! -w "${tool_dir}" ] && log_message "ERROR" "Tool directory not writable. Use 'nadimdr'." && return 1
    
    # Confirm deletion
    echo -e "${YELLOW}Warning: This will delete tool '$tool_name' and all its commands${RESET}"
    echo -n "Proceed? (y/n): "
    read confirm
    
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        rm -rf "$tool_dir"
        log_message "SUCCESS" "Tool '$tool_name' deleted"
    else
        log_message "INFO" "Deletion cancelled"
    fi
}

delete_tool "$@"
exit $?