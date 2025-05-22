#!/bin/bash
# utils.sh - Shell utilities
# License: GPL-3.0

source /usr/lib/nadim/platform/environment.sh

parse_args() {
    local args=("$@") i=0
    while [ $i -lt ${#args[@]} ]; do
        [ "${args[$i]}" = "-h" ] || [ "${args[$i]}" = "--help" ] && log_message "INFO" "Help requested" && return 1
        echo "${args[$i]}"
        i=$((i + 1))
    done
}

trim_whitespace() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"  # Enlève les espaces en début
    var="${var%"${var##*[![:space:]]}"}"  # Enlève les espaces en fin (corrigé ici)
    echo "$var"
}

create_file_with_header() {
    local file="$1" header="$2" content="${3:-}"
    local dir
    dir=$(dirname "$file")
    [ ! -d "$dir" ] && mkdir -p "$dir"
    cat > "$file" << INNER_EOF
#!/bin/bash
# $(basename "$file") - $header
# License: GPL-3.0

$content
INNER_EOF
    [[ "$file" == *.sh ]] && chmod +x "$file"
}
