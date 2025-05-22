#!/bin/bash
# interactive.sh - Interactive shell mode
# License: GPL-3.0

HIDE_FROM_HELP=1


source /usr/lib/nadim/platform/environment.sh
source /usr/lib/nadim/platform/helpers.sh
source /usr/lib/nadim/platform/autoload.sh
# Placeholder for background operation hooks
# To add background tasks (e.g., screen), implement:
# run_background() {
#     local cmd="$1"; shift
#     screen -dmS "nadim_$cmd" bash -c "/usr/lib/nadim/nadim.sh $cmd $*"
#     echo "Background session 'nadim_$cmd' started"
# }
# Add to command loop: if [[ "$input" =~ \&$ ]]; then run_background ...
launch_header
echo "Nadim interactive shell (type 'exit' to quit)"
export HISTFILE="$NADIM_SHELL_HISTORY_FILE" HISTSIZE=1000 HISTFILESIZE=2000
history -r "$HISTFILE" 2>/dev/null
while true; do
    read -e -p "nadim> " input
    history -s "$input"
    history -w "$HISTFILE" 2>/dev/null
    [ "$input" = "exit" ] && break
    [ -z "$input" ] && continue
    read -r first rest <<< "$input"
    save_command_to_history "$first" $rest
    process_command "$first" $rest
done
echo -e "\nExiting Nadim shell."
exit 0
