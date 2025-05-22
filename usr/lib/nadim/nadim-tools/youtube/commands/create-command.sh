#!/bin/bash
# create-command.sh - Create a new command for youtube
# License: GPL-3.0
HIDE_FROM_HELP=1

source /usr/lib/nadim/platform/environment.sh
source /usr/lib/nadim/platform/helpers.sh
source /usr/lib/nadim/nadim-tools/youtube/config.sh

create_command() {
    local cmd_name="$1"
    local hide_from_help="$2"
    
    # Interactive mode if no valid name provided
    if [ -z "$cmd_name" ] || [ "${cmd_name}" != "${cmd_name//[^a-zA-Z0-9_-]/}" ]; then
        echo -n "Command name (no spaces or special chars): "
        read cmd_name
        [ "${cmd_name}" != "${cmd_name//[^a-zA-Z0-9_-]/}" ] && log_message "ERROR" "Invalid command name" && return 1
        
        echo -n "Hide from help listing? (y/n): "
        read hide_response
        if [ "$hide_response" = "y" ] || [ "$hide_response" = "Y" ]; then
            hide_from_help=1
        else
            hide_from_help=0
        fi
    fi
    
    local cmd_path="${NADIM_TOOLS_DIR}/youtube/commands/${cmd_name}.sh"
    
    # Check if command already exists
    [ -f "$cmd_path" ] && log_message "ERROR" "Command '$cmd_name' already exists" && return 1
    
    # Create command file
    cat > "$cmd_path" << CMDEOF
#!/bin/bash
# ${cmd_name}.sh - Command for youtube
# License: GPL-3.0
HIDE_FROM_HELP=$hide_from_help

source /usr/lib/nadim/platform/environment.sh
source /usr/lib/nadim/platform/helpers.sh
source /usr/lib/nadim/nadim-tools/youtube/config.sh

# Your command implementation goes here
echo "Executing $cmd_name command for $TOOL_NAME"

exit 0
CMDEOF
    
    chmod 0755 "$cmd_path"
    log_message "SUCCESS" "Command '$cmd_name' created for 'youtube' tool!"
}

create_command "$@"
exit $?
