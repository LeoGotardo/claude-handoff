#!/bin/bash

# update.sh — update claude-handoff commands to latest version
# usage: bash update.sh [--force] [--check] [--skip-template] [--dir <path>] [--help]

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

ok()       { echo -e "  ${GREEN}updated${RESET}    $1"; }
current()  { echo -e "  ${DIM}ok         $1${RESET}"; }
skipped()  { echo -e "  ${YELLOW}skipped${RESET}    $1  ${DIM}$2${RESET}"; }
missing()  { echo -e "  ${YELLOW}missing${RESET}    $1  ${DIM}$2${RESET}"; }
outdated() { echo -e "  ${YELLOW}outdated${RESET}   $1"; }
fail()     { echo -e "  ${RED}failed${RESET}     $1  ${DIM}$2${RESET}"; }
warn()     { echo -e "${YELLOW}warning:${RESET} $*"; }
die()      { echo -e "${RED}error:${RESET} $*" >&2; exit 1; }

# ── flags ─────────────────────────────────────────────────────────────────────

FORCE=false
CHECK_ONLY=false
SKIP_TEMPLATE=false
TARGET="$DEFAULT_TARGET"

usage() {
  echo "usage: bash update.sh [options]"
  echo ""
  echo "  --force           overwrite all files including template without prompting"
  echo "  --check           show what is outdated without making changes"
  echo "  --skip-template   update commands but preserve local handoff-template.md"
  echo "  --dir <path>      target directory (default: ~/.claude/commands)"
  echo "  --help            show this message"
  exit 0
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --force)         FORCE=true; shift ;;
    --check)         CHECK_ONLY=true; shift ;;
    --skip-template) SKIP_TEMPLATE=true; shift ;;
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

if [ ! -d "$TARGET" ]; then
  die "install directory not found: $TARGET\nRun install.sh first, or pass --dir to specify a custom path."
fi

if [ ! -w "$TARGET" ] && [ "$CHECK_ONLY" = false ]; then
  die "directory not writable: $TARGET"
fi

# ── helpers ───────────────────────────────────────────────────────────────────

# fetch remote content into a variable; sets FETCH_STATUS to 0/1/2
REMOTE_CONTENT=""
fetch_remote() {
  local url="$1"
  local tmp
  tmp=$(mktemp)

  local http_code
  http_code=$(curl -fsSL --max-time 15 -w "%{http_code}" -o "$tmp" "$url" 2>/dev/null) || true

  if [ "$http_code" = "200" ] && [ -s "$tmp" ]; then
    REMOTE_CONTENT=$(cat "$tmp")
    rm -f "$tmp"
    FETCH_STATUS=0
  else
    REMOTE_CONTENT=""
    rm -f "$tmp"
    [ "$http_code" = "404" ] && FETCH_STATUS=2 || FETCH_STATUS=1
  fi
}

write_file() {
  local dest="$1"
  local content="$2"
  local tmp
  tmp=$(mktemp)
  echo "$content" > "$tmp"
  mv "$tmp" "$dest"
}

# detect files in target that look like handoff commands but aren't in COMMANDS
detect_renamed() {
  local found=()
  while IFS= read -r -d '' f; do
    local base
    base=$(basename "$f")
    local known=false
    for cmd in "${COMMANDS[@]}"; do
      [ "$base" = "$cmd" ] && known=true && break
    done
    $known || found+=("$base")
  done < <(find "$TARGET" -maxdepth 1 -name "handoff*.md" -print0 2>/dev/null)
  echo "${found[@]:-}"
}

# ── scan phase ────────────────────────────────────────────────────────────────

echo "Checking for updates (target: $TARGET)..."
echo ""

UPDATED=0
SKIPPED=0
FAILED=0
NOT_INSTALLED=0
FAILED_FILES=()
NOT_INSTALLED_FILES=()

declare -A REMOTE_CACHE

for cmd in "${COMMANDS[@]}"; do
  dest="$TARGET/$cmd"
  url="$BASE_URL/$cmd"

  # fetch remote once and cache
  fetch_remote "$url"
  remote_status=$FETCH_STATUS
  remote_content="$REMOTE_CONTENT"
  REMOTE_CACHE["$cmd"]="$remote_content"

  # file missing locally
  if [ ! -f "$dest" ]; then
    if [ "$remote_status" -eq 2 ]; then
      fail "$cmd" "(not found locally or remotely — may have been renamed)"
      FAILED=$((FAILED + 1))
      FAILED_FILES+=("$cmd")
    elif [ "$remote_status" -ne 0 ]; then
      fail "$cmd" "(not installed locally and remote fetch failed)"
      FAILED=$((FAILED + 1))
      FAILED_FILES+=("$cmd")
    else
      missing "$cmd" "(not installed — run install.sh or use --force to install now)"
      NOT_INSTALLED=$((NOT_INSTALLED + 1))
      NOT_INSTALLED_FILES+=("$cmd")
    fi
    continue
  fi

  # remote fetch failed
  if [ "$remote_status" -eq 2 ]; then
    fail "$cmd" "(file not found on remote — may have been renamed or removed)"
    FAILED=$((FAILED + 1))
    FAILED_FILES+=("$cmd")
    continue
  fi

  if [ "$remote_status" -ne 0 ]; then
    fail "$cmd" "(remote fetch failed — check connection and try again)"
    FAILED=$((FAILED + 1))
    FAILED_FILES+=("$cmd")
    continue
  fi

  # compare content
  local_content=$(cat "$dest")
  if [ "$remote_content" = "$local_content" ]; then
    current "$cmd"
    continue
  fi

  # file differs — handle template specially
  if [ "$cmd" = "handoff-template.md" ] && [ "$SKIP_TEMPLATE" = true ]; then
    skipped "$cmd" "(--skip-template)"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  if [ "$CHECK_ONLY" = true ]; then
    outdated "$cmd"
    UPDATED=$((UPDATED + 1))
    continue
  fi

  if [ "$cmd" = "handoff-template.md" ] && [ "$FORCE" = false ]; then
    echo ""
    printf "  ${YELLOW}outdated${RESET}   $cmd — you may have local customizations.\n"
    printf "  Overwrite? [y/N] "
    read -r answer
    if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
      skipped "$cmd" "(kept local version)"
      SKIPPED=$((SKIPPED + 1))
      continue
    fi
  fi

  write_file "$dest" "$remote_content"
  ok "$cmd"
  UPDATED=$((UPDATED + 1))

done

# ── detect unknown handoff files (possible renames) ───────────────────────────

RENAMED_FILES=$(detect_renamed)
if [ -n "$RENAMED_FILES" ]; then
  echo ""
  warn "found handoff files in $TARGET not in the known command list:"
  for f in $RENAMED_FILES; do
    echo "    $TARGET/$f"
  done
  echo "  These may be leftover from a rename. Remove them manually if they are no longer needed."
fi

# ── handle missing files with --force ─────────────────────────────────────────

if [ "$NOT_INSTALLED" -gt 0 ] && [ "$FORCE" = true ] && [ "$CHECK_ONLY" = false ]; then
  echo ""
  echo "Installing missing files (--force)..."
  for cmd in "${NOT_INSTALLED_FILES[@]}"; do
    dest="$TARGET/$cmd"
    remote_content="${REMOTE_CACHE[$cmd]:-}"
    if [ -n "$remote_content" ]; then
      write_file "$dest" "$remote_content"
      ok "$cmd"
      UPDATED=$((UPDATED + 1))
      NOT_INSTALLED=$((NOT_INSTALLED - 1))
    fi
  done
fi

# ── summary ───────────────────────────────────────────────────────────────────

echo ""

if [ "$CHECK_ONLY" = true ]; then
  if [ "$UPDATED" -gt 0 ]; then
    echo "$UPDATED file(s) outdated. Run update.sh to apply."
  elif [ "$NOT_INSTALLED" -gt 0 ]; then
    echo "Some files are not installed. Run install.sh or update.sh --force."
  elif [ "$FAILED" -gt 0 ]; then
    echo "Some files could not be checked. See errors above."
  else
    echo "All commands are up to date."
  fi
  [ "$FAILED" -gt 0 ] && exit 1
  exit 0
fi

if [ "$FAILED" -gt 0 ]; then
  warn "$FAILED file(s) had errors: ${FAILED_FILES[*]}"
fi

if [ "$NOT_INSTALLED" -gt 0 ]; then
  warn "$NOT_INSTALLED file(s) not installed: ${NOT_INSTALLED_FILES[*]}"
  echo "  Run install.sh to install them, or update.sh --force to install and update in one step."
fi

if [ "$UPDATED" -gt 0 ]; then
  echo "$UPDATED updated, $SKIPPED skipped, $FAILED failed."
elif [ "$FAILED" -eq 0 ] && [ "$NOT_INSTALLED" -eq 0 ]; then
  echo "Already up to date."
fi

[ "$FAILED" -gt 0 ] && exit 1
exit 0