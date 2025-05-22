#!/bin/bash
# autoload.sh - Command dispatcher
# License: GPL-3.0

source /usr/lib/nadim/platform/environment.sh
source /usr/lib/nadim/platform/helpers.sh

execute_tool_command() {
    local tool="$1" 
    local cmd="${2:-help}" 
    local cmd_path="${NADIM_TOOLS_DIR}/${tool}/commands/${cmd}.sh"
    
    if [ -f "$cmd_path" ]; then
        source "${NADIM_TOOLS_DIR}/${tool}/config.sh" 2>/dev/null
        
         # Only show version if header not already printed
        if [[ "$NADIM_HEADER_DISPLAYED" != "true" ]]; then
            echo -e "${CYAN}${NADIM_NAME} v${NADIM_VERSION}${RESET}\n"
            export NADIM_HEADER_DISPLAYED=true
        fi

        bash "$cmd_path" "${@:3}"
        local exit_code=$?
        conclusion_header
        return $exit_code
    fi
    
    log_message "ERROR" "Command not found: $tool $cmd"
    
    # Handle special case to avoid infinite recursion
    if [ "$tool" != "help" ] || [ "$cmd" != "help" ]; then
        execute_tool_command "help" "help"
    fi
    
    return 1
}

process_command() {
    local cmd="$1"
    shift
    
    # If no command specified, default to help
    if [ -z "$cmd" ]; then
        execute_tool_command "help" "help"
        return 0
    fi
    
    execute_tool_command "$cmd" "$@"
}