#!/bin/bash
# environment.sh - Nadim core environment settings
# License: GPL-3.0

# General metadata
export NADIM_ROOT="/usr/lib/nadim"
export NADIM_VERSION="1.0.0"
export NADIM_NAME="Nadim Dolphin Rescue"

# Core directories
export NADIM_TOOLS_DIR="$NADIM_ROOT/nadim-tools"
export NADIM_PLATFORM_DIR="$NADIM_ROOT/platform"
export NADIM_LIB_DIR="$NADIM_ROOT/lib"

# Per-user directory
export NADIM_USER_DIR="$NADIM_ROOT/users/$(whoami)"
if [ ! -d "$NADIM_USER_DIR" ]; then
  mkdir -p "$NADIM_USER_DIR" 2>/dev/null
  touch "$NADIM_USER_DIR/.nadim_command_history" "$NADIM_USER_DIR/.nadim_history" 2>/dev/null
fi

# Color definitions (if not disabled)
if [ -z "$NADIM_NO_COLOR" ]; then
  export RED='\033[0;31m'
  export GREEN='\033[0;32m'
  export YELLOW='\033[0;33m'
  export CYAN='\033[0;36m'
  export BOLD='\033[1m'
  export RESET='\033[0m'
fi

# Config and history files
export NADIM_CONFIG_FILE="$NADIM_USER_DIR/config.sh"
export NADIM_HISTORY_FILE="$NADIM_USER_DIR/.nadim_command_history"
export NADIM_SHELL_HISTORY_FILE="$NADIM_USER_DIR/.nadim_history"

# Fallback setting
NADIM_FALLBACK_ENABLED=0

# Load user config if available
[ -f "$NADIM_CONFIG_FILE" ] && source "$NADIM_CONFIG_FILE"
