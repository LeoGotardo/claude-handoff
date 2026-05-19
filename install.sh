#!/bin/bash

# install.sh — install claude-handoff commands globally
# usage: bash install.sh [--force] [--dir <path>] [--help]

set -euo pipefail

# ── config ────────────────────────────────────────────────────────────────────

REPO="LeoGotardo/claude-handoff"
BRANCH="master"
BASE_URL="https://raw.githubusercontent.com/$REPO/$BRANCH/.claude/commands"
DEFAULT_TARGET="$HOME/.claude/commands"

COMMANDS=(
  "handoff.md"
  "handoff-update.md"
  "handoff-catchup.md"
  "handoff-template.md"
)

# ── colors ────────────────────────────────────────────────────────────────────

if [ -t 1 ]; then
  GREEN="\033[0;32m"; YELLOW="\033[0;33m"; RED="\033[0;31m"; DIM="\033[2m"; RESET="\033[0m"
else
  GREEN=""; YELLOW=""; RED=""; DIM=""; RESET=""
fi

ok()   { echo -e "  ${GREEN}installed${RESET}  $1"; }
skip() { echo -e "  ${YELLOW}skipped${RESET}    $1  ${DIM}$2${RESET}"; }
fail() { echo -e "  ${RED}failed${RESET}     $1  ${DIM}$2${RESET}"; }
warn() { echo -e "${YELLOW}warning:${RESET} $*"; }
die()  { echo -e "${RED}error:${RESET} $*" >&2; exit 1; }

# ── flags ─────────────────────────────────────────────────────────────────────

FORCE=false
TARGET="$DEFAULT_TARGET"

usage() {
  echo "usage: bash install.sh [--force] [--dir <path>] [--help]"
  echo ""
  echo "  --force        overwrite existing files without prompting"
  echo "  --dir <path>   install to a custom directory (default: ~/.claude/commands)"
  echo "  --help         show this message"
  exit 0
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --force) FORCE=true; shift ;;
    --dir)
      [[ -z "${2:-}" ]] && die "--dir requires a path argument"
      TARGET="$2"; shift 2 ;;
    --help) usage ;;
    *) die "unknown option: $1. Run with --help for usage." ;;
  esac
done

# ── preflight checks ──────────────────────────────────────────────────────────

command -v curl >/dev/null 2>&1 || die "curl is required but not installed."

if ! curl -fsSL --max-time 5 "https://raw.githubusercontent.com" -o /dev/null 2>/dev/null; then
  die "cannot reach github.com — check your internet connection."
fi

# ── helpers ───────────────────────────────────────────────────────────────────

fetch_file() {
  local url="$1"
  local dest="$2"
  local tmp
  tmp=$(mktemp)

  local http_code
  http_code=$(curl -fsSL --max-time 15 -w "%{http_code}" -o "$tmp" "$url" 2>/dev/null) || true

  if [ "$http_code" = "200" ] && [ -s "$tmp" ]; then
    mv "$tmp" "$dest"
    return 0
  else
    rm -f "$tmp"
    [ "$http_code" = "404" ] && return 2
    return 1
  fi
}

# ── main ──────────────────────────────────────────────────────────────────────

echo "Installing claude-handoff commands..."
echo ""

if ! mkdir -p "$TARGET" 2>/dev/null; then
  die "cannot create directory: $TARGET"
fi

if [ ! -w "$TARGET" ]; then
  die "directory not writable: $TARGET"
fi

INSTALLED=0
SKIPPED=0
FAILED=0
FAILED_FILES=()

for cmd in "${COMMANDS[@]}"; do
  dest="$TARGET/$cmd"
  url="$BASE_URL/$cmd"

  if [ -f "$dest" ] && [ "$FORCE" = false ]; then
    skip "$cmd" "(already exists — use --force to overwrite)"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  fetch_file "$url" "$dest"
  status=$?

  case $status in
    0)
      ok "$cmd"
      INSTALLED=$((INSTALLED + 1))
      ;;
    2)
      fail "$cmd" "(not found on remote — file may have been renamed)"
      FAILED=$((FAILED + 1))
      FAILED_FILES+=("$cmd")
      ;;
    *)
      fail "$cmd" "(network error — check connection and try again)"
      FAILED=$((FAILED + 1))
      FAILED_FILES+=("$cmd")
      ;;
  esac

done

# ── summary ───────────────────────────────────────────────────────────────────

echo ""

if [ "$FAILED" -gt 0 ]; then
  warn "$FAILED file(s) failed to install: ${FAILED_FILES[*]}"
  echo ""
fi

if [ "$INSTALLED" -gt 0 ]; then
  echo "Done. $INSTALLED installed, $SKIPPED skipped, $FAILED failed."
  echo ""
  echo "Commands available in Claude Code:"
  echo "  /handoff         — create a new HANDOFF.md"
  echo "  /handoff-update  — update an existing HANDOFF.md"
  echo "  /handoff-catchup — resume work from an existing HANDOFF.md"
  echo ""
  echo "To customize the output structure, edit:"
  echo "  $TARGET/handoff-template.md"
elif [ "$SKIPPED" -gt 0 ] && [ "$FAILED" -eq 0 ]; then
  echo "All files already installed. Use --force to overwrite."
fi

[ "$FAILED" -gt 0 ] && exit 1
exit 0