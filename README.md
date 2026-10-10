# Log Analyzer

A modular Bash script that turns a raw application log into a quick, readable report: entry counts by severity, the most recent messages, the most frequent warnings and errors, the most active users, and activity per day.

Built as part of my Bash scripting / DevOps portfolio to practice structured shell scripting: input validation, small single-purpose functions, and a clean split between data and presentation.

## Features

- **Basic statistics**: total entries plus INFO / WARNING / ERROR counts
- **Recent messages**: last 5 entries for each level (INFO, WARNING, ERROR)
- **Most common messages**: ranked frequency of WARNING and ERROR messages
- **Most active users**: ranked by number of log entries
- **Entries by date**: how many entries were logged on each day
- **Input validation**: usage help, missing-file and non-regular-file checks

## Expected log format

The script reads space-separated fields, so each line must look like this:

```
YYYY-MM-DD HH:MM:SS LEVEL message text...
```

| Field | Meaning |
|-------|---------|
| `$1`  | Date (`YYYY-MM-DD`) |
| `$2`  | Time |
| `$3`  | Level: `INFO`, `WARNING` or `ERROR` |
| `$4+` | Message text |

For the "Most Active Users" section, user messages must follow the pattern `User <username> ...`, for example:

```
2026-10-01 09:15:02 INFO User alice logged in
2026-10-01 09:16:40 WARNING Disk usage at 85%
2026-10-01 09:17:11 ERROR Database connection timeout
```

Lines that don't match this format are still counted in the total, but they won't appear in the level, user or date breakdowns.

## Requirements

- Bash 4+
- Standard Unix tools: `awk`, `sort`, `uniq`, `tail`, `wc`
- `gawk` is recommended (the date filter uses a regex with `{n}` repetition, which some minimal awk versions such as older `mawk` do not support)

## Usage

```bash
chmod +x log_analyzer.sh
./log_analyzer.sh <log_file>
```

Example:

```bash
./log_analyzer.sh app.log
```

Running it with no arguments prints the usage message; pointing it at a missing file or a directory exits with a clear error.

## Output sections

The report prints in this order:

1. Basic Statistics
2. Recent INFO Messages
3. Recent WARNING Messages
4. Recent ERROR Messages
5. Most Common WARNING Messages
6. Most Common ERROR Messages
7. Most Active Users
8. Entries by Date

## Design notes

- **Data vs. presentation split**: `get_*` functions only compute and print raw data; `show_*` functions add headers and decide how it looks. Either layer can change without touching the other.
- **`set -e` is deliberately omitted**: `grep` and `awk` return a non-zero exit code when a filter finds nothing, which is a normal outcome here. With `-e` the script would die mid-report. `set -uo pipefail` is kept to catch unset variables and pipeline failures.
- **Everything is local**: functions use `local` variables to avoid leaking state.

## Project structure

```
.
├── log_analyzer.sh
└── README.md
```

## Possible improvements

- Support more levels (DEBUG, CRITICAL) or a configurable level list
- Optional flags, e.g. `--top N` or `--level ERROR`
- Sort "Entries by Date" chronologically instead of by count
- Handle other log formats (JSON logs, syslog)
- Add a sample `app.log` and automated tests (e.g. with `bats`)

## License

MIT (add a `LICENSE` file to the repo)
