#!/bin/bash
# create.sh - Create a new Nadim tool
# License: GPL-3.0

HIDE_FROM_HELP=1
DEV_COMMAND=1

source /usr/lib/nadim/platform/environment.sh
source /usr/lib/nadim/platform/helpers.sh
source /usr/lib/nadim/nadim-tools/tools/config.sh

launch_header true

create_tool() {
    local tool_name="$1" tool_desc="${2:-$1 tool}" alternative="${3:-}"
    
    # Interactive mode if no valid name provided
    if [ -z "$tool_name" ] || [ "${tool_name}" != "${tool_name//[^a-zA-Z0-9_-]/}" ]; then
        echo -n "Tool name (no spaces or special chars): "
        read tool_name
        [ "${tool_name}" != "${tool_name//[^a-zA-Z0-9_-]/}" ] && log_message "ERROR" "Invalid name" && return 1
        
        echo -n "Tool description: "
        read tool_desc
        
        echo -n "Alternative name (optional): "
        read alternative
        [ -n "$alternative" ] && [ "${alternative}" != "${alternative//[^a-zA-Z0-9_-]/}" ] && log_message "ERROR" "Invalid alternative name" && return 1
    fi
    
    local tool_dir="${NADIM_TOOLS_DIR}/${tool_name}"
    
    # Check if tool already exists
    [ -d "$tool_dir" ] && log_message "ERROR" "Tool '$tool_name' already exists" && return 1
    
    # Check write permissions
    [ ! -w "${NADIM_TOOLS_DIR}" ] && log_message "ERROR" "Tools directory not writable. Use 'nadimdr'." && return 1
    
    # Check for conflicting alternative names
    for dir in "${NADIM_TOOLS_DIR}"/*; do
        if [ -d "$dir" ] && [ -f "$dir/config.sh" ]; then
            source "$dir/config.sh" 2>/dev/null
            if [ "$TOOL_ALTERNATIVE" = "$tool_name" ]; then
                echo -e "${CYAN}Warning: '$tool_name' is an alternative for '$(basename "$dir")'${RESET}"
                echo -n "Use anyway? (y/n): " 
                read confirm 
                [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && return 1
            fi
        fi
    done
    
    # Create tool directory and commands subdirectory
    mkdir -m 0755 -p "${tool_dir}/commands"
    
    # Generate config file with proper escaping
    cat > "${tool_dir}/config.sh" << EOF
#!/bin/bash
# ${tool_name} tool configuration
TOOL_NAME="${tool_name}"
TOOL_DESCRIPTION="${tool_desc}"
TOOL_ALTERNATIVE="${alternative}"
TOOL_VERSION="1.0.0"
EOF
    chmod 0644 "${tool_dir}/config.sh"
    
    # Generate help command file
    cat > "${tool_dir}/commands/help.sh" << EOF
#!/bin/bash
# help.sh - Help command for ${tool_name}
# License: GPL-3.0

source /usr/lib/nadim/platform/environment.sh
source /usr/lib/nadim/platform/helpers.sh
source /usr/lib/nadim/nadim-tools/${tool_name}/config.sh

echo -e "\${BOLD}Tool: \$TOOL_NAME\${RESET}"
echo "Description: \$TOOL_DESCRIPTION"
echo -e "\n\${BOLD}Usage:\${RESET}"
echo " nadim \$TOOL_NAME <command>"
echo -e "\n\${BOLD}Available Commands:\${RESET}"
for f in "\${NADIM_TOOLS_DIR}/\$TOOL_NAME/commands"/*.sh; do
    if [ -f "\$f" ]; then
        cmd_name=\$(basename "\$f" .sh)
        
        # Skip commands marked with HIDE_FROM_HELP
        if grep -q "HIDE_FROM_HELP=1" "\$f"; then
            continue
        fi
        
        echo " \$cmd_name"
    fi
done
exit 0
EOF
    chmod 0755 "${tool_dir}/commands/help.sh"
    
    # Create the create-command script
    cat > "${tool_dir}/commands/create-command.sh" << EOF
#!/bin/bash
# create-command.sh - Create a new command for ${tool_name}
# License: GPL-3.0
HIDE_FROM_HELP=0

source /usr/lib/nadim/platform/environment.sh
source /usr/lib/nadim/platform/helpers.sh
source /usr/lib/nadim/nadim-tools/${tool_name}/config.sh

create_command() {
    local cmd_name="\$1"
    local hide_from_help="\$2"
    
    # Interactive mode if no valid name provided
    if [ -z "\$cmd_name" ] || [ "\${cmd_name}" != "\${cmd_name//[^a-zA-Z0-9_-]/}" ]; then
        echo -n "Command name (no spaces or special chars): "
        read cmd_name
        [ "\${cmd_name}" != "\${cmd_name//[^a-zA-Z0-9_-]/}" ] && log_message "ERROR" "Invalid command name" && return 1
        
        echo -n "Hide from help listing? (y/n): "
        read hide_response
        if [ "\$hide_response" = "y" ] || [ "\$hide_response" = "Y" ]; then
            hide_from_help=1
        else
            hide_from_help=0
        fi
    fi
    
    local cmd_path="\${NADIM_TOOLS_DIR}/${tool_name}/commands/\${cmd_name}.sh"
    
    # Check if command already exists
    [ -f "\$cmd_path" ] && log_message "ERROR" "Command '\$cmd_name' already exists" && return 1
    
    # Create command file
    cat > "\$cmd_path" << CMDEOF
#!/bin/bash
# \${cmd_name}.sh - Command for ${tool_name}
# License: GPL-3.0
HIDE_FROM_HELP=\$hide_from_help

source /usr/lib/nadim/platform/environment.sh
source /usr/lib/nadim/platform/helpers.sh
source /usr/lib/nadim/nadim-tools/${tool_name}/config.sh

# Your command implementation goes here
echo "Executing \$cmd_name command for \$TOOL_NAME"

exit 0
CMDEOF
    
    chmod 0755 "\$cmd_path"
    log_message "SUCCESS" "Command '\$cmd_name' created for '${tool_name}' tool!"
}

create_command "\$@"
exit \$?
EOF
    chmod 0755 "${tool_dir}/commands/create-command.sh"
    
    log_message "SUCCESS" "Tool '$tool_name' created! Try: nadim $tool_name help"
    echo "To create a new command for this tool, run: nadim $tool_name create-command"
}

create_tool "$@"
exit $?