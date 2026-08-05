#!/usr/bin/env bash

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BREWFILE="$ROOT/Brewfile"
VSCODE_EXTENSIONS="$ROOT/vscode/extensions.txt"
PACKAGES=(aerospace borders ghostty sketchybar vscode)
CODEX_AWAKE_SOURCE="$ROOT/macos/bin/codex-awake"
MEDIA_HELPER_BUILD="$ROOT/macos/yuttfu-media-helper/build-app.sh"
MEDIA_HELPER_AGENT_TEMPLATE="$ROOT/macos/LaunchAgents/com.yuttfu.sketchybar-media.plist.in"
failures=0

check_ok() {
  printf 'CHECK OK: %s\n' "$1"
}

check_fail() {
  printf 'CHECK FAILED: %s\n' "$1" >&2
  failures=$((failures + 1))
}

check_command() {
  local label="$1"
  local command_name="$2"

  if command -v "$command_name" >/dev/null 2>&1; then
    check_ok "$label"
  else
    check_fail "$label is not installed"
  fi
}

check_packages() {
  local package

  for package in "${PACKAGES[@]}"; do
    if [[ -d "$ROOT/$package" ]]; then
      check_ok "package $package"
    else
      check_fail "package $package is missing"
    fi
  done
}

check_links() {
  local package
  local output
  local status
  local conflicts=0

  if ! command -v stow >/dev/null 2>&1; then
    return
  fi

  for package in "${PACKAGES[@]}"; do
    output="$(stow --simulate --verbose=1 --dir "$ROOT" --target "$HOME" "$package" 2>&1)"
    status=$?
    if [[ "$status" -ne 0 ]]; then
      printf 'CONFLICT: package %s cannot be linked into %s\n' "$package" "$HOME" >&2
      printf '%s\n' "$output" >&2
      failures=$((failures + 1))
      conflicts=$((conflicts + 1))
    fi
  done

  local codex_awake_target="$HOME/.local/bin/codex-awake"
  if [[ -e "$codex_awake_target" || -L "$codex_awake_target" ]]; then
    if [[ -L "$codex_awake_target" ]] &&
       [[ "$(readlink "$codex_awake_target")" == "$CODEX_AWAKE_SOURCE" ]]; then
      :
    else
      printf 'CONFLICT: %s is not managed by this repository\n' "$codex_awake_target" >&2
      failures=$((failures + 1))
      conflicts=$((conflicts + 1))
    fi
  fi

  if [[ "$conflicts" -eq 0 ]]; then
    check_ok "no link conflicts"
  fi
}

run_checks() {
  failures=0

  if [[ "$(uname -s)" == "Darwin" ]]; then
    check_ok "macOS"
  else
    check_fail "macOS is required"
  fi

  check_command "Homebrew" brew
  check_command "Stow" stow

  if [[ -f "$BREWFILE" ]]; then
    check_ok "Brewfile"
  else
    check_fail "Brewfile is missing"
  fi

  check_packages
  check_links

  [[ "$failures" -eq 0 ]]
}

link_packages() {
  local package

  for package in "${PACKAGES[@]}"; do
    stow --dir "$ROOT" --target "$HOME" "$package"
  done
}

link_codex_awake() {
  local target="$HOME/.local/bin/codex-awake"

  mkdir -p "$HOME/.local/bin"
  if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$CODEX_AWAKE_SOURCE" ]]; then
    return
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    printf 'CONFLICT: %s is not managed by this repository\n' "$target" >&2
    return 1
  fi

  ln -s "$CODEX_AWAKE_SOURCE" "$target"
}

install_media_helper() {
  local app_target="$HOME/Applications/yuttfu Media Helper.app"
  local agent_target="$HOME/Library/LaunchAgents/com.yuttfu.sketchybar-media.plist"
  local agent_temp

  "$MEDIA_HELPER_BUILD" "$app_target" || return 1
  mkdir -p "$(dirname "$agent_target")"
  agent_temp="$(mktemp "${TMPDIR:-/tmp}/yuttfu-media-agent.XXXXXX")"
  sed "s|__HOME__|$HOME|g" "$MEDIA_HELPER_AGENT_TEMPLATE" >"$agent_temp"
  mv "$agent_temp" "$agent_target"
  printf 'APPLY OK: yuttfu Media Helper installed\n'
}

apply_links() {
  if ! run_checks; then
    return 1
  fi

  link_packages
  link_codex_awake
  printf 'APPLY OK: dotfiles linked\n'
}

install_dependencies() {
  brew bundle install --file "$BREWFILE"
  printf 'APPLY OK: dependencies installed\n'
}

resolve_code_cli() {
  if command -v code >/dev/null 2>&1; then
    command -v code
    return
  fi

  local application_cli='/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code'
  if [[ -x "$application_cli" ]]; then
    printf '%s\n' "$application_cli"
    return
  fi

  return 1
}

restore_vscode_extensions() {
  local code_cli
  local extension
  local installed_extensions

  if [[ ! -f "$VSCODE_EXTENSIONS" ]]; then
    printf 'VS Code extension manifest is missing: %s\n' "$VSCODE_EXTENSIONS" >&2
    return 1
  fi

  if ! code_cli="$(resolve_code_cli)"; then
    printf 'VS Code CLI is unavailable after dependency installation.\n' >&2
    return 1
  fi

  installed_extensions="$("$code_cli" --list-extensions 2>/dev/null || true)"
  while IFS= read -r extension || [[ -n "$extension" ]]; do
    [[ -z "$extension" || "$extension" == \#* ]] && continue
    if ! printf '%s\n' "$installed_extensions" | /usr/bin/grep -Fxiq "$extension"; then
      "$code_cli" --install-extension "$extension"
    fi
  done <"$VSCODE_EXTENSIONS"

  printf 'APPLY OK: VS Code extensions restored\n'
}

apply_all() {
  if [[ "$links_only" -eq 0 ]]; then
    install_dependencies
  fi

  apply_links

  if [[ "$links_only" -eq 0 ]]; then
    install_media_helper || return 1
    restore_vscode_extensions
  fi
}

usage() {
  printf 'Usage: %s --check | --apply [--links-only]\n' "${0##*/}"
}

mode="${1:---check}"
if [[ "$#" -gt 0 ]]; then
  shift
fi

links_only=0
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --links-only)
      links_only=1
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
    if [[ "$links_only" -ne 0 ]]; then
      usage >&2
      exit 2
    fi
    run_checks
    exit $?
    ;;
  --apply)
    apply_all
    ;;
  --help|-h)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
