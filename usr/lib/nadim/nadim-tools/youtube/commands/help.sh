#!/bin/bash
# help.sh - Help command for YouTube transcription tool
# License: GPL-3.0

source /usr/lib/nadim/platform/environment.sh
source /usr/lib/nadim/platform/helpers.sh
source /usr/lib/nadim/nadim-tools/youtube/config.sh

clear
echo -e "\n=============================================================="
echo -e "          YouTube Transcription Tool - Help"
echo -e "==============================================================\n"

echo -e "${BOLD}Tool:${RESET} $TOOL_NAME"
echo -e "${BOLD}Description:${RESET} $TOOL_DESCRIPTION\n"

echo -e "${BOLD}Usage:${RESET}"
echo -e "  nadim $TOOL_NAME <command> [options]\n"

echo -e "${BOLD}Available Commands:${RESET}"
for f in "${NADIM_TOOLS_DIR}/$TOOL_NAME/commands"/*.sh; do
    if [ -f "$f" ]; then
        cmd_name=$(basename "$f" .sh)
        
        # Skip commands marked with HIDE_FROM_HELP
        if grep -q "HIDE_FROM_HELP=1" "$f"; then
            continue
        fi
        
        echo -e "  $cmd_name"
    fi
done
echo

echo -e "${BOLD}Options:${RESET}"
echo -e "  lang=LANG                 Language for subtitles (e.g., en, fr, en.*)"
echo -e "  -replace \"FROM\" \"TO\"  Replace text in transcription"
echo -e "  -merge                    Combine all transcriptions into single file"
echo -e "  -i                        Ignore case when replacing text\n"

echo -e "${BOLD}Examples:${RESET}"
echo -e "  nadim $TOOL_NAME single https://www.youtube.com/watch?v=FdZikRU97CI lang=fr"
echo -e "  nadim $TOOL_NAME fromfile my_links.txt lang=en -replace \"word\" \"replacement\""
echo -e "  nadim $TOOL_NAME playlist https://www.youtube.com/playlist?list=ID -merge\n"

echo -e "${BOLD}Files:${RESET}"
echo -e "  Output directory: $NADIM_OUTPUT_DIR"
echo -e "  Queue status:     $QUEUE_DIR"
echo -e "  Logs:             $LOG_DIR"
echo -e "  Transcripts:      $TRANSCRIPT_DIR\n"

exit 0