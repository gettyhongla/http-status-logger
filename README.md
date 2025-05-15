# HTTP Status Logger (Bash Learning Project)

This script logs random HTTP status codes and their descriptions at fixed intervals, stores them in a `.txt` file, and exports the logs to a clean `.csv` file — all using pure Bash. It's designed as a hands-on Bash scripting project to help you practice and retain core scripting concepts like background processes, `IFS`, `awk`, `jq`, `sed`, signal handling, and more.

---

## 🎯 Purpose

The goal of this script is twofolds for now...:

1. **Build a realistic logging utility** that:
   - Pulls live JSON data from GitHub
   - Randomly logs HTTP status codes in structured format
   - Allows interactive inspection via terminal
   - Exports structured CSV reports

2. **Reinforce advanced Bash scripting skills**, including:
   - Reading and parsing JSON with `jq`
   - Working with arrays and `IFS`
   - Handling background processes, timers, and signals
   - Writing readable and maintainable Bash code

---

## 📦 Features

- ✅ Fetches live HTTP status code definitions via `curl` + `jq`
- ✅ Uses arrays and safe parsing with `IFS= read -r`
- ✅ Logs random entries to `http_status_log.txt` for a set duration
- ✅ Exports structured data to `http_code_status.csv`
- ✅ Tracks unique entry numbers across sessions (no resets)
- ✅ Interactive terminal input (get specific log entries, check PID, exit cleanly)
- ✅ Adds clear session demarcations in the CSV

---

## 🛠️ Technologies Practiced

| Concept         | Tools/Commands Used                    |
|-----------------|-----------------------------------------|
| Parse JSON      | `jq`                                    |
| Array handling  | `status_list=(); while IFS= read ...`   |
| Regex extract   | `grep -o`, `awk -F`, `cut`              |
| String cleanup  | `sed`, `xargs`                          |
| Interactive CLI | `read -p`, case-insensitive input       |
| Time control    | `sleep`, `date`, elapsed calculation    |
| Background jobs | `log_status_codes &`, `wait $!`, `kill` |
| Safe export     | `awk`, CSV formatting, `[[ -z ... ]]`   |

---
