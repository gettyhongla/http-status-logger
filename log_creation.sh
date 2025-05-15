#!/bin/bash

# CONFIG
log_file="http_status_log.txt"
csv_file="http_code_status.csv"
max_duration=500 #seconds
interval=5        # seconds between logs

# Download JSON response and set it as a variable then if statement will check if $json is empty and if so it prints error mssg
json=$(curl -s https://raw.githubusercontent.com/for-GET/know-your-http-well/master/json/status-codes.json)
if [[ -z "$json" ]]; then
    echo "❌ Failed to fetch status codes JSON. Check your internet connection."
    exit 1
fi

# Load status list safely (works on ubuntu & macOS too)
status_list=()
while IFS= read -r line; do
    status_list+=("$line")
done < <(echo "$json" | jq -r '.[] | "\(.code): \(.phrase) --- \(.description)"')

# works in ubuntu but not macOS because this fails silently due to bash version (no error, but status_list ends up empty)
# mapfile -t status_list < <(echo "$json" | jq -r '.[] | "\(.code): \(.phrase) --- \(.description)"')

# Sanity check
if [[ ${#status_list[@]} -eq 0 ]]; then
    echo "❌ Failed to load HTTP status codes. Exiting."
    exit 1
fi

# Clear current session log
> "$log_file"

# Background logger
log_status_codes() {
    exec > "$log_file" 2>&1
    counter=1
    start_time=$(date +%s)

    while true; do
        current_time=$(date +%s)
        elapsed=$((current_time - start_time))
        if [[ $elapsed -ge $max_duration ]]; then break; fi

        entry="${status_list[RANDOM % ${#status_list[@]}]}"
        entry_cleaned=$(echo "$entry" | sed 's/\"/\x27/g')
        timestamp=$(date +"%b %d, %Y %I:%M %p")
        echo "[$counter.]  $entry_cleaned  |  $timestamp"
        ((counter++))
        sleep "$interval"
    done
}

# Start logger in background
log_status_codes &
log_pid=$!

echo "▶️ Logging started in background (PID $log_pid)"
echo "📁 Logging to $log_file"
echo "⌛ Will auto-export to CSV after $max_duration seconds"

# Interaction loop
while true; do
    read -p "Enter log number, 'status', 'pid', or 'exit': " input
    input_lower=$(echo "$input" | tr '[:upper:]' '[:lower:]')

    if [[ "$input_lower" == "exit" ]]; then
        kill "$log_pid"
        echo "🛑 Logger stopped. Goodbye!"
        break

    elif [[ "$input_lower" == "0" || "$input_lower" == "pid" ]]; then
        echo "🆔 Logger PID: $log_pid"
        continue

    elif [[ "$input_lower" == "status" ]]; then
        entry_count=$(grep -o '^\[[0-9]\+\.\]' "$log_file" | sed 's/[^0-9]//g' | sort -n | tail -n1)
        [[ -z "$entry_count" ]] && echo "📭 No entries yet." || echo "📊 Entries logged: $entry_count"
        continue

    elif [[ "$input_lower" =~ ^[0-9]+$ ]]; then
        entry_count=$(grep -o '^\[[0-9]\+\.\]' "$log_file" | sed 's/[^0-9]//g' | sort -n | tail -n1)
        if [[ -z "$entry_count" ]]; then
            echo "⏳ No log entries yet."
            continue
        fi
        if (( input >= 1 && input <= entry_count )); then
            result=$(grep "^\[$input\." "$log_file")
            echo "🧾 $result"
        else
            echo "❌ Entry $input not available. Max is $entry_count."
        fi

    else
        echo "⚠️ Invalid input. Try a number, 'status', 'pid', or 'exit'."
    fi
done

# Wait for logger to finish --> This suppresses the "Terminated: 15" output and avoids the script failing because of it.
wait $log_pid 2>/dev/null || true

# CSV Export
if [[ -f "$log_file" ]]; then
    # Ensure CSV header
    if [[ ! -s "$csv_file" ]] || ! grep -q '^Entry Number,Code,Phrase,Description,Timestamp' "$csv_file"; then
        echo "Entry Number,Code,Phrase,Description,Timestamp" > "$csv_file"
        global_counter=0
    else
        # Extract last used entry number (quoted or not)
        global_counter=$(awk -F',' '
            $1 ~ /^[0-9]+$/ {if ($1 > max) max=$1}
            $1 ~ /^\"[0-9]+\"$/ {n=substr($1,2,length($1)-2); if (n > max) max=n}
            END {print max}' "$csv_file")
        [[ -z "$global_counter" ]] && global_counter=0

        # Add session marker
        if (( global_counter > 0 )); then
            timestamp_now=$(date +"%b %d, %Y %I:%M %p")
            echo "--- NEW SESSION STARTED: $timestamp_now ---" >> "$csv_file"
        fi
    fi

    # Read and format entries
    while IFS= read -r line; do
        code=$(echo "$line" | awk -F'] ' '{print $2}' | cut -d':' -f1 | xargs)
        phrase=$(echo "$line" | awk -F':' '{print $2}' | awk -F'---' '{print $1}' | xargs)
        description=$(echo "$line" | awk -F'---' '{print $2}' | awk -F'|' '{print $1}' | xargs)
        timestamp=$(echo "$line" | awk -F'|' '{print $2}' | xargs)

        phrase_clean=$(echo "$phrase" | sed 's/\"//g')
        description_clean=$(echo "$description" | sed 's/\"//g')

        ((global_counter++))
        echo "$global_counter,$code,$phrase_clean,$description_clean,$timestamp" >> "$csv_file"
    done < "$log_file"

    echo "✅ Export complete → $csv_file"
fi
