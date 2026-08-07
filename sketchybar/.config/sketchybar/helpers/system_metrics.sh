#!/bin/bash

set -u

if [[ -n "${YUTTFU_METRICS_CPU_FIXTURE:-}" && -n "${YUTTFU_METRICS_MEMORY_FIXTURE:-}" ]]; then
  printf 'cpu=%s mem=%s\n' "$YUTTFU_METRICS_CPU_FIXTURE" "$YUTTFU_METRICS_MEMORY_FIXTURE"
  exit 0
fi

logical_cpus="$(/usr/bin/getconf _NPROCESSORS_ONLN 2>/dev/null || printf '1')"
raw_cpu="$(/bin/ps -A -o %cpu= 2>/dev/null | /usr/bin/awk '{ total += $1 } END { printf "%.2f", total + 0 }')"
cpu="$(/usr/bin/awk -v total="$raw_cpu" -v cores="$logical_cpus" 'BEGIN {
  if (cores < 1) cores = 1
  value = total / cores
  if (value < 0) value = 0
  if (value > 100) value = 100
  printf "%.1f", value
}')"

free_memory="$(/usr/bin/memory_pressure -Q 2>/dev/null | /usr/bin/awk -F': ' '
  /free percentage/ {
    gsub(/%/, "", $2)
    print $2
    exit
  }
')"
memory="$(/usr/bin/awk -v free="${free_memory:-100}" 'BEGIN {
  value = 100 - free
  if (value < 0) value = 0
  if (value > 100) value = 100
  printf "%.1f", value
}')"

printf 'cpu=%s mem=%s\n' "$cpu" "$memory"
