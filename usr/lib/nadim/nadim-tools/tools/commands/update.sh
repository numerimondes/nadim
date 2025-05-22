#!/bin/bash
# update.sh - Update an existing Nadim tool
# License: GPL-3.0

source /usr/lib/nadim/platform/environment.sh
source /usr/lib/nadim/platform/helpers.sh
source /usr/lib/nadim/nadim-tools/tools/config.sh

update_tool() {
    local tool_name="$1" tool_desc="$2" alternative="$3"
    
    # Interactive mode if no tool specified
    if [ -z "$tool_name" ]; then
        echo -n "Tool name to update: "
        read tool_name
    fi
    
    local tool_dir="${NADIM_TOOLS_DIR}/${tool_name}"
    
    # Check if tool exists
    [ ! -d "$tool_dir" ] && log_message "ERROR" "Tool '$tool_name' doesn't exist" && return 1
    
    # Check write permissions
    [ ! -w "${tool_dir}" ] && log_message "ERROR" "Tool directory not writable. Use 'nadimdr'." && return 1
    
    # Load existing config
    source "${tool_dir}/config.sh" 2>/dev/null
    
    if [ -z "$tool_desc" ]; then
        echo -n "Tool description [${TOOL_DESCRIPTION}]: "
        read tool_desc
        [ -z "$tool_desc" ] && tool_desc="$TOOL_DESCRIPTION"
    fi
    
    if [ -z "$alternative" ]; then
        echo -n "Alternative name [${TOOL_ALTERNATIVE}]: "
        read alternative
        [ -z "$alternative" ] && alternative="$TOOL_ALTERNATIVE"
    fi
    
    [ -n "$alternative" ] && [ "${alternative}" != "${alternative//[^a-zA-Z0-9_-]/}" ] && log_message "ERROR" "Invalid alternative name" && return 1
    
    # Check for conflicting alternative names
    if [ -n "$alternative" ] && [ "$alternative" != "$TOOL_ALTERNATIVE" ]; then
        for dir in "${NADIM_TOOLS_DIR}"/*; do
            if [ -d "$dir" ] && [ "$(basename "$dir")" != "$tool_name" ] && [ -f "$dir/config.sh" ]; then
                source "$dir/config.sh" 2>/dev/null
                if [ "$TOOL_ALTERNATIVE" = "$alternative" ]; then
                    echo -e "${CYAN}Warning: '$alternative' is an alternative for '$(basename "$dir")'${RESET}"
                    echo -n "Use anyway? (y/n): " 
                    read confirm 
                    [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && return 1
                fi
            fi
        done
    fi
    
    # Update config file
    cat > "${tool_dir}/config.sh" << EOF
#!/bin/bash
# ${tool_name} tool configuration
TOOL_NAME="${tool_name}"
TOOL_DESCRIPTION="${tool_desc}"
TOOL_ALTERNATIVE="${alternative}"
TOOL_VERSION="1.0.0"
EOF
    chmod 0644 "${tool_dir}/config.sh"
    
    log_message "SUCCESS" "Tool '$tool_name' updated!"
}

update_tool "$@"
exit $?