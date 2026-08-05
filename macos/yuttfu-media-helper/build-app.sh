#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT="${1:-$ROOT/dist/yuttfu Media Helper.app}"
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
  swift build \
  --package-path "$ROOT" \
  --scratch-path "$TEMP_ROOT/build" \
  --cache-path "$TEMP_ROOT/cache" \
  --config-path "$TEMP_ROOT/config" \
  --security-path "$TEMP_ROOT/security" \
  --manifest-cache none \
  --disable-sandbox \
  -c release \
  --product yuttfu-media-helper

APP="$TEMP_ROOT/yuttfu Media Helper.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$TEMP_ROOT/build/release/yuttfu-media-helper" "$APP/Contents/MacOS/yuttfu-media-helper"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
/usr/bin/codesign --force --deep --sign - "$APP" >/dev/null

if [[ -e "$OUTPUT" ]]; then
  if [[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$OUTPUT/Contents/Info.plist" 2>/dev/null || true)" != "com.yuttfu.sketchybar-media" ]]; then
    printf 'Refusing to overwrite unmanaged app: %s\n' "$OUTPUT" >&2
    exit 1
  fi
  rm -rf "$OUTPUT"
fi
mkdir -p "$(dirname "$OUTPUT")"
mv "$APP" "$OUTPUT"
printf 'BUILT: %s\n' "$OUTPUT"
