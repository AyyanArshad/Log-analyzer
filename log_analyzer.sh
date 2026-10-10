#!/usr/bin/env bash
set -uo pipefail
# Note: -e deliberately omitted for now — grep/awk returning "no matches" (exit 1)
# is a normal, expected outcome in this script, not a fatal error. Enabling -e
# would kill the script mid-report the first time a filter finds zero results.

# ---------- VALIDATION ----------

validate_arguments() {
    if [ $# -eq 0 ]; then
        echo "Usage: ./log_analyzer.sh <log_file>"
        echo "Example: ./log_analyzer.sh app.log"
        exit 1
    fi
}

validate_file() {
    local file="$1"

    if [ ! -e "$file" ]; then
        echo "Error: Log file '$file' does not exist."
        exit 1
    fi

    if [ ! -f "$file" ]; then
        echo "Error: '$file' is not a regular file."
        exit 1
    fi
}

# ---------- ANALYSIS (DATA) ----------
# These functions only compute and print raw data. No banners, no headers.

get_basic_stats() {
    local file="$1"
    local total info warning error

    total=$(wc -l < "$file")
    read -r info warning error <<< "$(awk '
        $3 == "INFO"    { info++ }
        $3 == "WARNING" { warning++ }
        $3 == "ERROR"   { error++ }
        END { print info+0, warning+0, error+0 }
    ' "$file")"

    echo "$total $info $warning $error"
}

get_recent_messages() {
    local file="$1"
    local level="$2"
    awk -v lvl="$level" '$3 == lvl' "$file" | tail -5
}

get_common_messages() {
    local file="$1"
    local level="$2"
    awk -v lvl="$level" '
        $3 == lvl {
            sep=""
            for (i=4; i<=NF; i++) { printf "%s%s", sep, $i; sep=" " }
            print ""
        }
    ' "$file" | sort | uniq -c | sort -nr
}

get_active_users() {
    local file="$1"
    awk '$4 == "User" { print $5 }' "$file" | sort | uniq -c | sort -nr
}

get_entries_by_date() {
    local file="$1"
    awk '$1 ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/ {print $1}' "$file" | sort | uniq -c | sort -rn
}
# ---------- PRESENTATION ----------
# These functions own formatting and printing. They call the DATA functions
# above and decide how the result looks on screen.

print_header() {
    echo
    echo "==================================================="
    echo "                $1"
    echo "==================================================="
}

show_basic_statistics() {
    local file="$1"
    local total info warning error
    read -r total info warning error <<< "$(get_basic_stats "$file")"

    print_header "BASIC STATISTICS"
    echo "Total Entries : $total"
    echo "INFO          : $info"
    echo "WARNING       : $warning"
    echo "ERROR         : $error"
}

show_recent_messages() {
    local file="$1"
    local level="$2"
    print_header "RECENT $level MESSAGES"
    get_recent_messages "$file" "$level"
}

show_common_messages() {
    local file="$1"
    local level="$2"
    print_header "MOST COMMON $level MESSAGES"
    get_common_messages "$file" "$level"
}

show_active_users() {
    local file="$1"
    print_header "MOST ACTIVE USERS"
    get_active_users "$file"
}

show_entries_by_date() {
    local file="$1"
    print_header "ENTRIES BY DATE"
    get_entries_by_date "$file"
}

# ---------- MAIN ----------

main() {
    validate_arguments "$@"
    local filename="$1"
    validate_file "$filename"

    show_basic_statistics "$filename"
    show_recent_messages "$filename" "INFO"
    show_recent_messages "$filename" "WARNING"
    show_recent_messages "$filename" "ERROR"
    show_common_messages "$filename" "WARNING"
    show_common_messages "$filename" "ERROR"
    show_active_users "$filename"
    show_entries_by_date "$filename"
}

main "$@"
