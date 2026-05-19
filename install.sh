#!/bin/bash

set -e

REPO="LeoGotardo/claude-handoff"
BRANCH="master"
BASE_URL="https://raw.githubusercontent.com/$REPO/$BRANCH/.claude/commands"
TARGET="$HOME/.claude/commands"

echo "Installing Claude Code handoff commands..."

mkdir -p "$TARGET"

curl -fsSL "$BASE_URL/handoff.md" -o "$TARGET/handoff.md"
curl -fsSL "$BASE_URL/handoff-update.md" -o "$TARGET/handoff-update.md"
curl -fsSL "$BASE_URL/handoff-catchup.md" -o "$TARGET/handoff-catchup.md"
curl -fsSL "$BASE_URL/handoff-template.md" -o "$TARGET/handoff-template.md"

echo ""
echo "Done. Commands available globally in Claude Code:"
echo "  /handoff         — create a new HANDOFF.md"
echo "  /handoff-update  — update an existing HANDOFF.md"
echo "  /handoff-catchup — resume work from an existing HANDOFF.md"
echo ""
echo "To customize the output structure, edit:"
echo "  ~/.claude/commands/handoff-template.md"