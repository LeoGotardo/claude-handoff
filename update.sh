#!/bin/bash

set -e

REPO="LeoGotardo/claude-handoff"
BRANCH="master"
BASE_URL="https://raw.githubusercontent.com/$REPO/$BRANCH/.claude/commands"
TARGET="$HOME/.claude/commands"

COMMANDS=(
  "handoff.md"
  "handoff-update.md"
  "handoff-catchup.md"
  "handoff-template.md"
)

# ── helpers ──────────────────────────────────────────────────────────────────

check_installed() {
  for cmd in "${COMMANDS[@]}"; do
    if [ ! -f "$TARGET/$cmd" ]; then
      echo "Error: $cmd not found in $TARGET"
      echo "Run install.sh first."
      exit 1
    fi
  done
}

fetch_remote_version() {
  local file="$1"
  curl -fsSL "$BASE_URL/$file" 2>/dev/null
}

files_differ() {
  local file="$1"
  local remote
  remote=$(fetch_remote_version "$file")
  local local_content
  local_content=$(cat "$TARGET/$file")
  [ "$remote" != "$local_content" ]
}

# ── flags ─────────────────────────────────────────────────────────────────────

FORCE=false
CHECK_ONLY=false
SKIP_TEMPLATE=false

for arg in "$@"; do
  case $arg in
    --force)         FORCE=true ;;
    --check)         CHECK_ONLY=true ;;
    --skip-template) SKIP_TEMPLATE=true ;;
  esac
done

# ── main ──────────────────────────────────────────────────────────────────────

echo "Checking for updates..."
echo ""

check_installed

UPDATED=0
SKIPPED=0
UNCHANGED=0

for cmd in "${COMMANDS[@]}"; do

  # optionally skip template to preserve local customizations
  if [ "$SKIP_TEMPLATE" = true ] && [ "$cmd" = "handoff-template.md" ]; then
    echo "  skipped  $cmd (--skip-template)"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  if files_differ "$cmd"; then
    if [ "$CHECK_ONLY" = true ]; then
      echo "  outdated $cmd"
      UPDATED=$((UPDATED + 1))
      continue
    fi

    if [ "$FORCE" = false ] && [ "$cmd" = "handoff-template.md" ]; then
      printf "  %-12s %s — overwrite local customizations? [y/N] " "outdated" "$cmd"
      read -r answer
      if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
        echo "  skipped  $cmd"
        SKIPPED=$((SKIPPED + 1))
        continue
      fi
    fi

    fetch_remote_version "$cmd" > "$TARGET/$cmd"
    echo "  updated  $cmd"
    UPDATED=$((UPDATED + 1))
  else
    echo "  ok       $cmd"
    UNCHANGED=$((UNCHANGED + 1))
  fi

done

echo ""

if [ "$CHECK_ONLY" = true ]; then
  if [ "$UPDATED" -gt 0 ]; then
    echo "$UPDATED file(s) outdated. Run update.sh to apply."
  else
    echo "All commands are up to date."
  fi
  exit 0
fi

if [ "$UPDATED" -gt 0 ]; then
  echo "$UPDATED updated, $UNCHANGED unchanged, $SKIPPED skipped."
else
  echo "Already up to date."
fi