#!/bin/bash

set -u

if [[ "${YUTTFU_OBS_TEST_RUNNING:-}" == "0" ]]; then
  printf 'off\n'
  exit 0
fi

if [[ "${YUTTFU_OBS_TEST_RUNNING:-}" != "1" ]] && ! /usr/bin/pgrep -x OBS >/dev/null 2>&1; then
  printf 'off\n'
  exit 0
fi

latest_log="${YUTTFU_OBS_LOG_FIXTURE:-}"
if [[ -z "$latest_log" ]]; then
  log_directory="$HOME/Library/Application Support/obs-studio/logs"
  latest_log=""
  for candidate in "$log_directory"/*.txt; do
    [[ -f "$candidate" ]] || continue
    if [[ -z "$latest_log" || "$candidate" -nt "$latest_log" ]]; then
      latest_log="$candidate"
    fi
  done
fi

if [[ -z "$latest_log" || ! -r "$latest_log" ]]; then
  printf 'ready\n'
  exit 0
fi

state="$(/usr/bin/awk '
  /==== Recording Start/ { state = "recording" }
  /==== Recording Stop/ { state = "ready" }
  END { print state }
' "$latest_log")"

printf '%s\n' "${state:-ready}"
