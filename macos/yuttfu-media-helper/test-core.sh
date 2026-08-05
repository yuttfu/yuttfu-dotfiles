#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEMP_ROOT"' EXIT

select_sdk() {
  local candidate
  local candidates=(
    "$(xcrun --show-sdk-path 2>/dev/null || true)"
    /Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
  )

  for candidate in "${candidates[@]}"; do
    [[ -d "$candidate" ]] || continue
    if printf 'import Foundation\n' | \
       CLANG_MODULE_CACHE_PATH="$TEMP_ROOT/module-cache" \
       swiftc -sdk "$candidate" -module-cache-path "$TEMP_ROOT/module-cache" -typecheck - >/dev/null 2>&1; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

SDK_PATH="$(select_sdk)" || {
  printf 'No compatible macOS Swift SDK was found. Reinstall Xcode Command Line Tools.\n' >&2
  exit 1
}

SDKROOT="$SDK_PATH" CLANG_MODULE_CACHE_PATH="$TEMP_ROOT/module-cache" \
  swift run \
  --package-path "$ROOT" \
  --scratch-path "$TEMP_ROOT/build" \
  --cache-path "$TEMP_ROOT/cache" \
  --config-path "$TEMP_ROOT/config" \
  --security-path "$TEMP_ROOT/security" \
  --manifest-cache none \
  --disable-sandbox \
  yuttfu-media-core-tests
