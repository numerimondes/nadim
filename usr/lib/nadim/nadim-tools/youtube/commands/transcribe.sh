#!/bin/bash
# transcribe.sh - YouTube transcription tool with enhanced queue management
# License: GPL-3.0
# Version: 2.0

set -euo pipefail

# Configuration and dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HIDE_FROM_HELP=0

# Source platform files if they exist
[[ -f "/usr/lib/nadim/platform/environment.sh" ]] && source "/usr/lib/nadim/platform/environment.sh"
[[ -f "/usr/lib/nadim/platform/helpers.sh" ]] && source "/usr/lib/nadim/platform/helpers.sh"
[[ -f "/usr/lib/nadim/nadim-tools/youtube/config.sh" ]] && source "/usr/lib/nadim/nadim-tools/youtube/config.sh"

# Directory structure
TOOL_NAME="${TOOL_NAME:-youtube-transcriber}"
BASE_DIR="${HOME}/nadim-outputs/${TOOL_NAME}"
QUEUE_DIR="${BASE_DIR}/queue"
COMPLETED_DIR="${BASE_DIR}/completed"
LOG_DIR="${BASE_DIR}/logs"
TRANSCRIPT_DIR="${BASE_DIR}/transcripts"
CONFIG_FILE="${BASE_DIR}/config.json"
QUEUE_FILE="${QUEUE_DIR}/sessions.csv"

# Global variables
SCRIPT_NAME="$(basename "$0")"
SESSION_ID=""
SUPPORTED_LANGS=("en" "fr" "es" "de" "it" "pt" "ru" "ja" "ko" "zh")
DEFAULT_LANG="en"
MAX_RETRIES=3
RETRY_DELAY=5
CLEANUP_DAYS=30

# Color codes for better UX
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log() {
    local level="$1"
    local message="$2"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    local log_file="${LOG_DIR}/${SESSION_ID:-system}/session.log"
    
    mkdir -p "$(dirname "$log_file")"
    echo "[$timestamp] [$level] $message" >> "$log_file"
    
    case "$level" in
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" >&2 ;;
        "WARNING") echo -e "${YELLOW}[WARNING]${NC} $message" ;;
        "SUCCESS") echo -e "${GREEN}[SUCCESS]${NC} $message" ;;
        "INFO") echo -e "${BLUE}[INFO]${NC} $message" ;;
        *) echo "$message" ;;
    esac
}

# Initialize directory structure
init_environment() {
    local dirs=("$BASE_DIR" "$QUEUE_DIR" "$COMPLETED_DIR" "$LOG_DIR" "$TRANSCRIPT_DIR")
    
    for dir in "${dirs[@]}"; do
        if ! mkdir -p "$dir"; then
            log "ERROR" "Cannot create directory: $dir"
            exit 1
        fi
    done
    
    # Initialize queue file if it doesn't exist
    if [[ ! -f "$QUEUE_FILE" ]]; then
        echo "session_id,mode,source,status,started,completed,language,output_path,success_count,failed_count" > "$QUEUE_FILE"
    fi
    
    # Create default config if it doesn't exist
    if [[ ! -f "$CONFIG_FILE" ]]; then
        cat > "$CONFIG_FILE" << EOF
{
    "default_language": "$DEFAULT_LANG",
    "max_retries": $MAX_RETRIES,
    "retry_delay": $RETRY_DELAY,
    "cleanup_days": $CLEANUP_DAYS,
    "notifications_enabled": true
}
EOF
    fi
}

# Check system dependencies
check_dependencies() {
    local missing_deps=()
    local required_commands=("yt-dlp" "jq" "curl")
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log "ERROR" "Missing required dependencies: ${missing_deps[*]}"
        echo "Please install missing dependencies:"
        for dep in "${missing_deps[@]}"; do
            case "$dep" in
                "yt-dlp") echo "  pip install yt-dlp" ;;
                "jq") echo "  apt install jq  # or  brew install jq" ;;
                "curl") echo "  apt install curl  # or  brew install curl" ;;
            esac
        done
        exit 1
    fi
}

# Display main menu
show_main_menu() {
    while true; do
        clear
        echo -e "${CYAN}=== YouTube Transcription Manager ===${NC}"
        echo -e "${CYAN}====================================${NC}\n"
        
        # Display active sessions
        display_session_summary
        
        echo -e "\n${BLUE}Available Options:${NC}"
        echo "  1. Start new transcription"
        echo "  2. Manage existing sessions"
        echo "  3. View completed transcriptions"
        echo "  4. System maintenance"
        echo "  5. Settings"
        echo "  6. Exit"
        
        echo -ne "\n${CYAN}Enter your choice (1-6): ${NC}"
        read -r choice
        
        case "$choice" in
            1) start_new_transcription ;;
            2) manage_sessions ;;
            3) view_completed_transcriptions ;;
            4) system_maintenance ;;
            5) manage_settings ;;
            6) exit_gracefully ;;
            *) 
                log "WARNING" "Invalid choice: $choice"
                echo -e "${RED}Invalid choice. Please enter a number between 1-6.${NC}"
                read -p "Press Enter to continue..." -r
                ;;
        esac
    done
}

# Display session summary
display_session_summary() {
    local total_sessions running_sessions completed_sessions failed_sessions
    
    if [[ ! -f "$QUEUE_FILE" ]] || [[ $(wc -l < "$QUEUE_FILE") -eq 1 ]]; then
        echo -e "${YELLOW}No active sessions${NC}"
        return
    fi
    
    total_sessions=$(tail -n +2 "$QUEUE_FILE" | wc -l)
    running_sessions=$(tail -n +2 "$QUEUE_FILE" | awk -F',' '$4=="running"' | wc -l)
    completed_sessions=$(tail -n +2 "$QUEUE_FILE" | awk -F',' '$4=="completed"' | wc -l)
    failed_sessions=$(tail -n +2 "$QUEUE_FILE" | awk -F',' '$4=="failed"' | wc -l)
    
    echo -e "${BLUE}Session Summary:${NC}"
    echo "  Total: $total_sessions | Running: $running_sessions | Completed: $completed_sessions | Failed: $failed_sessions"
}

# Start new transcription workflow
start_new_transcription() {
    clear
    echo -e "${CYAN}=== New Transcription Session ===${NC}\n"
    
    # Get transcription mode
    echo -e "${BLUE}Select transcription mode:${NC}"
    echo "  1. Single video URL"
    echo "  2. Multiple videos from file"
    echo "  3. YouTube playlist"
    echo "  4. YouTube channel (latest videos)"
    
    echo -ne "\n${CYAN}Enter mode (1-4): ${NC}"
    read -r mode
    
    case "$mode" in
        1) transcribe_single_video ;;
        2) transcribe_from_file ;;
        3) transcribe_playlist ;;
        4) transcribe_channel ;;
        *) 
            log "WARNING" "Invalid mode selected: $mode"
            echo -e "${RED}Invalid mode. Returning to main menu.${NC}"
            sleep 2
            return
            ;;
    esac
}

# Transcribe single video
transcribe_single_video() {
    echo -ne "\n${CYAN}Enter video URL: ${NC}"
    read -r url
    
    if ! validate_youtube_url "$url"; then
        log "ERROR" "Invalid YouTube URL: $url"
        echo -e "${RED}Invalid YouTube URL. Please check and try again.${NC}"
        read -p "Press Enter to continue..." -r
        return
    fi
    
    local language
    language=$(select_language)
    
    SESSION_ID=$(generate_session_id)
    log "INFO" "Starting single video transcription: $url"
    
    create_session "single" "$url" "$language"
    start_background_job "$SESSION_ID"
    
    echo -e "${GREEN}Transcription started! Session ID: $SESSION_ID${NC}"
    read -p "Press Enter to continue..." -r
}

# Transcribe from file
transcribe_from_file() {
    echo -ne "\n${CYAN}Enter file path containing URLs (one per line): ${NC}"
    read -r file_path
    
    if [[ ! -f "$file_path" ]]; then
        log "ERROR" "File not found: $file_path"
        echo -e "${RED}File not found. Please check the path and try again.${NC}"
        read -p "Press Enter to continue..." -r
        return
    fi
    
    local url_count
    url_count=$(grep -c "^https://\|^http://\|^www\." "$file_path" 2>/dev/null || echo "0")
    
    if [[ $url_count -eq 0 ]]; then
        log "ERROR" "No valid URLs found in file: $file_path"
        echo -e "${RED}No valid URLs found in the file.${NC}"
        read -p "Press Enter to continue..." -r
        return
    fi
    
    echo -e "${BLUE}Found $url_count URLs in file${NC}"
    
    local language
    language=$(select_language)
    
    SESSION_ID=$(generate_session_id)
    log "INFO" "Starting batch transcription from file: $file_path ($url_count URLs)"
    
    create_session "batch" "$file_path" "$language"
    start_background_job "$SESSION_ID"
    
    echo -e "${GREEN}Batch transcription started! Session ID: $SESSION_ID${NC}"
    read -p "Press Enter to continue..." -r
}

# Transcribe playlist
transcribe_playlist() {
    echo -ne "\n${CYAN}Enter playlist URL: ${NC}"
    read -r playlist_url
    
    if ! validate_youtube_url "$playlist_url"; then
        log "ERROR" "Invalid YouTube playlist URL: $playlist_url"
        echo -e "${RED}Invalid YouTube playlist URL.${NC}"
        read -p "Press Enter to continue..." -r
        return
    fi
    
    echo -e "${BLUE}Checking playlist...${NC}"
    
    # Get playlist info
    local playlist_info
    playlist_info=$(yt-dlp --flat-playlist --dump-json "$playlist_url" 2>/dev/null | head -1)
    
    if [[ -z "$playlist_info" ]]; then
        log "ERROR" "Unable to access playlist: $playlist_url"
        echo -e "${RED}Unable to access playlist. Please check the URL and try again.${NC}"
        read -p "Press Enter to continue..." -r
        return
    fi
    
    local video_count
    video_count=$(yt-dlp --flat-playlist --get-id "$playlist_url" 2>/dev/null | wc -l)
    
    echo -e "${BLUE}Playlist contains $video_count videos${NC}"
    
    local language
    language=$(select_language)
    
    SESSION_ID=$(generate_session_id)
    log "INFO" "Starting playlist transcription: $playlist_url ($video_count videos)"
    
    create_session "playlist" "$playlist_url" "$language"
    start_background_job "$SESSION_ID"
    
    echo -e "${GREEN}Playlist transcription started! Session ID: $SESSION_ID${NC}"
    read -p "Press Enter to continue..." -r
}

# Language selection
select_language() {
    echo -e "\n${BLUE}Select language for transcription:${NC}"
    for i in "${!SUPPORTED_LANGS[@]}"; do
        echo "  $((i+1)). ${SUPPORTED_LANGS[$i]}"
    done
    
    echo -ne "\n${CYAN}Enter choice (1-${#SUPPORTED_LANGS[@]}) or press Enter for default ($DEFAULT_LANG): ${NC}"
    read -r lang_choice
    
    if [[ -z "$lang_choice" ]]; then
        echo "$DEFAULT_LANG"
    elif [[ "$lang_choice" =~ ^[0-9]+$ ]] && [[ $lang_choice -ge 1 ]] && [[ $lang_choice -le ${#SUPPORTED_LANGS[@]} ]]; then
        echo "${SUPPORTED_LANGS[$((lang_choice-1))]}"
    else
        log "WARNING" "Invalid language choice, using default: $DEFAULT_LANG"
        echo "$DEFAULT_LANG"
    fi
}

# Validate YouTube URL
validate_youtube_url() {
    local url="$1"
    [[ "$url" =~ ^https?://(www\.)?(youtube\.com|youtu\.be) ]]
}

# Generate unique session ID
generate_session_id() {
    echo "$(date +%Y%m%d_%H%M%S)_$$"
}

# Create session entry
create_session() {
    local mode="$1"
    local source="$2"
    local language="$3"
    local timestamp="$(date -Iseconds)"
    
    mkdir -p "$LOG_DIR/$SESSION_ID" "$TRANSCRIPT_DIR/$SESSION_ID"
    
    echo "$SESSION_ID,$mode,$source,queued,$timestamp,,$language,$TRANSCRIPT_DIR/$SESSION_ID,0,0" >> "$QUEUE_FILE"
    
    log "INFO" "Created session $SESSION_ID with mode $mode"
}

# Start background processing job
start_background_job() {
    local session_id="$1"
    
    # Update status to running
    update_session_status "$session_id" "running"
    
    # Start background process
    nohup bash "$0" --execute "$session_id" >/dev/null 2>&1 &
    local job_pid=$!
    
    # Store PID for potential cleanup
    echo "$job_pid" > "$LOG_DIR/$session_id/pid"
    
    log "INFO" "Started background job for session $session_id (PID: $job_pid)"
}

# Background execution handler
execute_session() {
    local session_id="$1"
    SESSION_ID="$session_id"
    
    log "INFO" "Starting execution for session $session_id"
    
    # Get session details
    local session_data
    session_data=$(grep "^$session_id," "$QUEUE_FILE" | head -1)
    
    if [[ -z "$session_data" ]]; then
        log "ERROR" "Session not found: $session_id"
        exit 1
    fi
    
    IFS=',' read -r sid mode source status started completed language output_path success_count failed_count <<< "$session_data"
    
    local urls=()
    
    # Prepare URL list based on mode
    case "$mode" in
        "single")
            urls=("$source")
            ;;
        "batch")
            mapfile -t urls < <(grep -E "^https?://" "$source" 2>/dev/null || true)
            ;;
        "playlist")
            mapfile -t urls < <(yt-dlp --flat-playlist --get-url "$source" 2>/dev/null || true)
            ;;
    esac
    
    if [[ ${#urls[@]} -eq 0 ]]; then
        log "ERROR" "No URLs to process for session $session_id"
        update_session_status "$session_id" "failed"
        exit 1
    fi
    
    log "INFO" "Processing ${#urls[@]} URLs for session $session_id"
    
    local success_count=0
    local failed_count=0
    
    # Process each URL
    for i in "${!urls[@]}"; do
        local url="${urls[$i]}"
        local current=$((i + 1))
        local total=${#urls[@]}
        
        log "INFO" "Processing video $current/$total: $url"
        
        if process_single_url "$url" "$session_id" "$language" "$current"; then
            ((success_count++))
        else
            ((failed_count++))
        fi
        
        # Update progress
        update_session_progress "$session_id" "$success_count" "$failed_count"
    done
    
    # Final status update
    local final_status="completed"
    if [[ $failed_count -gt 0 ]] && [[ $success_count -eq 0 ]]; then
        final_status="failed"
    elif [[ $failed_count -gt 0 ]]; then
        final_status="partial"
    fi
    
    update_session_status "$session_id" "$final_status"
    
    # Send notification if available
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "YouTube Transcription" "Session $session_id completed: $success_count succeeded, $failed_count failed" 2>/dev/null || true
    fi
    
    log "SUCCESS" "Session $session_id completed: $success_count succeeded, $failed_count failed"
}

# Process single URL
process_single_url() {
    local url="$1"
    local session_id="$2"
    local language="$3"
    local index="$4"
    
    local video_id
    video_id=$(echo "$url" | grep -oP '(?:v=|/)([a-zA-Z0-9_-]{11})' | tail -c 12 || echo "unknown_${index}")
    
    local output_file="$TRANSCRIPT_DIR/$session_id/${video_id}.txt"
    local temp_file="$TRANSCRIPT_DIR/$session_id/${video_id}.temp"
    
    log "INFO" "Processing video ID: $video_id"
    
    # Attempt transcription with retries
    for attempt in $(seq 1 $MAX_RETRIES); do
        log "INFO" "Attempt $attempt/$MAX_RETRIES for video $video_id"
        
        if yt-dlp \
            --write-subs \
            --write-auto-subs \
            --sub-langs "$language" \
            --sub-format "srt" \
            --skip-download \
            --output "$temp_file" \
            "$url" > "$LOG_DIR/$session_id/yt-dlp_${video_id}.log" 2>&1; then
            
            # Convert SRT to clean text
            if convert_srt_to_text "$temp_file.$language.srt" "$output_file"; then
                # Clean up temporary files
                rm -f "$temp_file"* 2>/dev/null || true
                log "SUCCESS" "Successfully transcribed video $video_id"
                return 0
            fi
        fi
        
        if [[ $attempt -lt $MAX_RETRIES ]]; then
            local delay=$((RETRY_DELAY * attempt))
            log "WARNING" "Attempt $attempt failed for video $video_id, retrying in ${delay}s"
            sleep "$delay"
        fi
    done
    
    log "ERROR" "Failed to transcribe video $video_id after $MAX_RETRIES attempts"
    return 1
}

# Convert SRT to clean text
convert_srt_to_text() {
    local srt_file="$1"
    local output_file="$2"
    
    if [[ ! -f "$srt_file" ]]; then
        log "ERROR" "SRT file not found: $srt_file"
        return 1
    fi
    
    # Convert SRT to plain text, removing timestamps and duplicate lines
    sed -n '/^[0-9]/!p' "$srt_file" | \
    sed '/^$/d' | \
    sed 's/<[^>]*>//g' | \
    awk '!seen[$0]++' > "$output_file"
    
    if [[ -s "$output_file" ]]; then
        log "SUCCESS" "Converted SRT to text: $output_file"
        return 0
    else
        log "ERROR" "Failed to convert SRT to text"
        return 1
    fi
}

# Update session status
update_session_status() {
    local session_id="$1"
    local new_status="$2"
    local timestamp="$(date -Iseconds)"
    
    local temp_file="$QUEUE_FILE.tmp"
    
    awk -F',' -v OFS=',' -v sid="$session_id" -v status="$new_status" -v ts="$timestamp" '
        NR==1 {print; next}
        $1==sid {$4=status; if(status=="completed" || status=="failed" || status=="partial") $6=ts; print; next}
        {print}
    ' "$QUEUE_FILE" > "$temp_file" && mv "$temp_file" "$QUEUE_FILE"
    
    log "INFO" "Updated session $session_id status to $new_status"
}

# Update session progress
update_session_progress() {
    local session_id="$1"
    local success_count="$2"
    local failed_count="$3"
    
    local temp_file="$QUEUE_FILE.tmp"
    
    awk -F',' -v OFS=',' -v sid="$session_id" -v succ="$success_count" -v fail="$failed_count" '
        NR==1 {print; next}
        $1==sid {$9=succ; $10=fail; print; next}
        {print}
    ' "$QUEUE_FILE" > "$temp_file" && mv "$temp_file" "$QUEUE_FILE"
}

# Manage existing sessions
manage_sessions() {
    while true; do
        clear
        echo -e "${CYAN}=== Session Management ===${NC}\n"
        
        # Display sessions
        if ! display_sessions_table; then
            echo -e "${YELLOW}No sessions found.${NC}"
            read -p "Press Enter to return to main menu..." -r
            return
        fi
        
        echo -e "\n${BLUE}Options:${NC}"
        echo "  1. View session details"
        echo "  2. Cancel running session"
        echo "  3. Retry failed session"
        echo "  4. Delete session"
        echo "  5. Return to main menu"
        
        echo -ne "\n${CYAN}Enter choice (1-5): ${NC}"
        read -r choice
        
        case "$choice" in
            1) view_session_details ;;
            2) cancel_session ;;
            3) retry_session ;;
            4) delete_session ;;
            5) return ;;
            *) 
                echo -e "${RED}Invalid choice.${NC}"
                read -p "Press Enter to continue..." -r
                ;;
        esac
    done
}

# Display sessions in table format
display_sessions_table() {
    if [[ ! -f "$QUEUE_FILE" ]] || [[ $(wc -l < "$QUEUE_FILE") -eq 1 ]]; then
        return 1
    fi
    
    echo -e "${BLUE}Current Sessions:${NC}"
    printf "%-20s %-10s %-12s %-10s %-10s\n" "Session ID" "Mode" "Status" "Success" "Failed"
    echo "────────────────────────────────────────────────────────────────"
    
    tail -n +2 "$QUEUE_FILE" | while IFS=',' read -r session_id mode source status started completed language output_path success_count failed_count; do
        printf "%-20s %-10s %-12s %-10s %-10s\n" \
            "${session_id:0:20}" \
            "$mode" \
            "$status" \
            "${success_count:-0}" \
            "${failed_count:-0}"
    done
    
    return 0
}

# System maintenance menu
system_maintenance() {
    while true; do
        clear
        echo -e "${CYAN}=== System Maintenance ===${NC}\n"
        
        echo -e "${BLUE}Available Options:${NC}"
        echo "  1. Clean old sessions (>$CLEANUP_DAYS days)"
        echo "  2. Check disk usage"
        echo "  3. Verify dependencies"
        echo "  4. Export session data"
        echo "  5. Return to main menu"
        
        echo -ne "\n${CYAN}Enter choice (1-5): ${NC}"
        read -r choice
        
        case "$choice" in
            1) clean_old_sessions ;;
            2) check_disk_usage ;;
            3) verify_dependencies ;;
            4) export_session_data ;;
            5) return ;;
            *) 
                echo -e "${RED}Invalid choice.${NC}"
                read -p "Press Enter to continue..." -r
                ;;
        esac
    done
}

# Clean old sessions
clean_old_sessions() {
    echo -e "${BLUE}Cleaning sessions older than $CLEANUP_DAYS days...${NC}"
    
    local cutoff_date
    cutoff_date=$(date -d "$CLEANUP_DAYS days ago" +%s)
    local cleaned_count=0
    
    # Create backup
    cp "$QUEUE_FILE" "$QUEUE_FILE.backup.$(date +%s)"
    
    # Process sessions
    local temp_file="$QUEUE_FILE.tmp"
    {
        head -1 "$QUEUE_FILE"  # Keep header
        tail -n +2 "$QUEUE_FILE" | while IFS=',' read -r session_id mode source status started completed language output_path success_count failed_count; do
            local session_date
            session_date=$(date -d "$started" +%s 2>/dev/null || echo "0")
            
            if [[ $session_date -lt $cutoff_date ]]; then
                # Remove session files
                rm -rf "$LOG_DIR/$session_id" "$TRANSCRIPT_DIR/$session_id" 2>/dev/null || true
                ((cleaned_count++))
                log "INFO" "Cleaned old session: $session_id"
            else
                echo "$session_id,$mode,$source,$status,$started,$completed,$language,$output_path,$success_count,$failed_count"
            fi
        done
    } > "$temp_file" && mv "$temp_file" "$QUEUE_FILE"
    
    echo -e "${GREEN}Cleaned $cleaned_count old sessions.${NC}"
    read -p "Press Enter to continue..." -r
}

# Check disk usage
check_disk_usage() {
    echo -e "${BLUE}Disk Usage Analysis:${NC}\n"
    
    echo "Base directory: $BASE_DIR"
    if [[ -d "$BASE_DIR" ]]; then
        du -sh "$BASE_DIR"
        echo
        du -sh "$BASE_DIR"/* 2>/dev/null | sort -hr || true
    else
        echo "Directory not found"
    fi
    
    echo
    read -p "Press Enter to continue..." -r
}

# Verify dependencies
verify_dependencies() {
    echo -e "${BLUE}Verifying system dependencies...${NC}\n"
    
    local deps=("yt-dlp" "jq" "curl" "awk" "sed")
    local all_good=true
    
    for dep in "${deps[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then
            local version
            case "$dep" in
                "yt-dlp") version=$(yt-dlp --version 2>/dev/null || echo "unknown") ;;
                "jq") version=$(jq --version 2>/dev/null || echo "unknown") ;;
                "curl") version=$(curl --version 2>/dev/null | head -1 || echo "unknown") ;;
                *) version="available" ;;
            esac
            echo -e "${GREEN}✓${NC} $dep: $version"
        else
            echo -e "${RED}✗${NC} $dep: not found"
            all_good=false
        fi
    done
    
    echo
    if $all_good; then
        echo -e "${GREEN}All dependencies are satisfied.${NC}"
    else
        echo -e "${RED}Some dependencies are missing. Please install them.${NC}"
    fi
    
    read -p "Press Enter to continue..." -r
}

# Exit gracefully
exit_gracefully() {
    echo -e "\n${CYAN}Thank you for using YouTube Transcription Manager!${NC}"
    
    # Check for running sessions
    local running_count
    running_count=$(tail -n +2 "$QUEUE_FILE" 2>/dev/null | awk -F',' '$4=="running"' | wc -l)
    
    if [[ $running_count -gt 0 ]]; then
        echo -e "${YELLOW}Warning: $running_count session(s) are still running.${NC}"
        echo -e "${YELLOW}They will continue in the background.${NC}"
    fi
    
    exit 0
}

# Main execution logic
main() {
    # Handle command line arguments
    if [[ $# -gt 0 ]]; then
        case "$1" in
            "--execute")
                if [[ $# -eq 2 ]]; then
                    execute_session "$2"
                else
                    log "ERROR" "Invalid arguments for --execute"
                    exit 1
                fi
                ;;
            "--help"|"-h")
                show_help
                exit 0
                ;;
            *)
                log "ERROR" "Unknown argument: $1"
                exit 1
                ;;
        esac
    else
        # Interactive mode
        check_dependencies
        init_environment
        show_main_menu
    fi
}

# Show help
show_help() {
    cat << EOF
YouTube Transcription Manager

USAGE:
    $SCRIPT_NAME [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    --execute SESSION   Execute transcription for session (internal use)

DESCRIPTION:
    Interactive tool for transcribing YouTube videos, playlists, and channels.
    Supports multiple languages and provides session management.

EXAMPLES:
    $SCRIPT_NAME                    # Start interactive mode
    $SCRIPT_NAME --help            # Show help

FILES:
    Config:      $CONFIG_FILE
    Queue:       $QUEUE_FILE
    Logs:        $LOG_DIR
    Transcripts: $TRANSCRIPT_DIR

EOF
}

# Run main function
main "$@"