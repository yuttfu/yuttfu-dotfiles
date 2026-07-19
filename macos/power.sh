#!/usr/bin/env bash

set -euo pipefail

PMSET_BIN="${PMSET_BIN:-/usr/bin/pmset}"

usage() {
  printf 'Usage: %s --check | --apply [--dry-run]\n' "${0##*/}"
}

print_profile() {
  "$PMSET_BIN" -g custom | /usr/bin/awk '
    /^Battery Power:/ { section = "battery"; next }
    /^AC Power:/ { section = "ac"; next }
    $1 == "displaysleep" { display[section] = $2 }
    $1 == "sleep" { sleep[section] = $2 }
    END {
      if (display["ac"] == "" || sleep["ac"] == "" ||
          display["battery"] == "" || sleep["battery"] == "") {
        exit 1
      }
      printf "AC Power: displaysleep=%s sleep=%s\n", display["ac"], sleep["ac"]
      printf "Battery Power: displaysleep=%s sleep=%s\n", display["battery"], sleep["battery"]
    }
  '
}

apply_setting() {
  printf 'PLAN: sudo /usr/bin/pmset'
  printf ' %s' "$@"
  printf '\n'

  if [[ "$dry_run" -eq 0 ]]; then
    /usr/bin/sudo /usr/bin/pmset "$@"
  fi
}

mode="${1:---check}"
if [[ "$#" -gt 0 ]]; then
  shift
fi

dry_run=0
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --dry-run)
      dry_run=1
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
  shift
done

case "$mode" in
  --check)
    if [[ "$dry_run" -ne 0 ]]; then
      usage >&2
      exit 2
    fi
    print_profile
    ;;
  --apply)
    apply_setting -c displaysleep 30 sleep 0
    apply_setting -b displaysleep 10 sleep 15
    ;;
  --help|-h)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
