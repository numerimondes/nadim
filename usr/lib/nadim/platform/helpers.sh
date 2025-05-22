#!/bin/bash
# helpers.sh - Nadim helper functions
# License: GPL-3.0

# Colors
RESET="\033[0m"
CYAN="\033[0;36m"
BOLD="\033[1m"
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"

# Header
launch_header() {
    local show_ascii="${1:-false}"
    if [ "$show_ascii" = true ]; then
        echo -e "${CYAN}${BOLD}" 
        echo " ⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣠⡶⠗⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ "
        echo " ⠀⠀⠀⠀⠀⠀⣠⣶⣿⣿⣿⡟⠐⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ "
        echo " ⠀⠀⠀⠀⢀⣼⣿⣿⣿⣿⠟⠠⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ "
        echo " ⠀⠀⠀⠀⣾⣿⣿⣿⣿⣿⡠⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ "
        echo " ⠀⢀⣴⣾⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ "
        echo " ⢠⣿⣿⣿⡏⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ "
        echo " ⣿⠿⠿⣿⡷⣿⣿⣿⠀⢸⣿⣷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ "
        echo " ⠀⠀⠀⢹⣧⣿⣿⣿⠀⠸⠘⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ "
        echo " ⠀⠀⠀⠈⣿⣹⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ "
        echo " ⠀⠀⠀⠀⠸⣿⣿⣿⣷⡸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ "
        echo " ⠀⠀⠀⠀⠀⠹⣿⣿⣿⣿⣦⡀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⡀⠀⠀⠀⠀⠀⠀ "
        echo " ⠀⠀⠀⠀⠀⠀⠈⠻⢿⣿⣿⣿⣷⣶⣤⣤⣴⣶⣿⣿⣿⡏⠀⠀⠀⠀⠀⠀⠀ "
        echo " ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠉⠙⠛⠻⢿⣿⣿⣿⡋⠉⠀⠀⠀⠀⠀⠀⠀⢠ "
        echo " ⠀⠀⠀⠀⠀⠀⠰⠀⠀⠀⠀⠄⠂⡀⠨⠉⢻⣿⣟⣿⠀⠀⠀⢀⠀⡀⢠⡀⠀ "
        echo " ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠁⠀⠀⠈⠂⠂⠁⢠⢿⣿⡒⠡⠂⠂⠐⠰⠁⡀⠂ "
        echo " ⠀⠀⠀⠀⠀⡄⠀⠀⡄⠆⠀⠀⠁⠀⠀⠀⠀⠀⠀⠉⠀⠀⠀⠀⠀⠀⠘⠠⠀ "
        echo " ⠀⠀⠀⡄⠀⠀⡄⠆⠀⠀⠁⠀⠀⠁⠀⠀⠀⠉⠀⠀⠀⠀⠀⠀⠘⠠⠀ "
        echo "  _⠁  _     ⠁ ⠁   _ _           "
        echo " | \\ | |   ⠁     | (_)   ⠁      "
        echo " |  \\| | __ _  __| |_ _ __ ___"
        echo " | . \` |/ _\` |/ _\` | | '_ \` _ \\ "
        echo " | |\\  | (_| | (_| | | | | | | |"
        echo " \\_| \\_/\\__,_|\\__,_|_|_| |_| |_|"
        echo -e "${RESET}"
        echo -e "${CYAN}${NADIM_NAME} v${NADIM_VERSION}${RESET}\n"
        export NADIM_HEADER_DISPLAYED=true
    fi
}
# Footer
conclusion_header() {
    echo -e "${GREEN}${BOLD}Operation completed successfully!${RESET}\n"
}

log_message() {
    local level="$1"
    local msg="$2"
    case "$level" in
        INFO) echo -e "${CYAN}[INFO]${RESET} $msg" ;;
        ERROR) echo -e "${RED}[ERROR]${RESET} $msg" ;;
        SUCCESS) echo -e "${GREEN}[SUCCESS]${RESET} $msg" ;;
        WARNING) echo -e "${YELLOW}[WARNING]${RESET} $msg" ;;
        *) echo -e "[$level] $msg" ;;
    esac
}

save_command_to_history() {
    local cmd="$1"
    shift
    echo "$cmd $*" >> "$NADIM_HISTORY_FILE"
    tail -n 1000 "$NADIM_HISTORY_FILE" > "${NADIM_HISTORY_FILE}.tmp" && mv "${NADIM_HISTORY_FILE}.tmp" "$NADIM_HISTORY_FILE"
}

check_dependencies() {
    local deps="bash sed grep"
    local missing=""
    for dep in $deps; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing="$missing $dep"
        fi
    done
    if [ -n "$missing" ]; then
        log_message "WARNING" "Missing dependencies:$missing"
        return 1
    fi
    return 0
}