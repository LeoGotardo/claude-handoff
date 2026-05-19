#!/bin/bash

set -e

REPO="seu-usuario/claude-handoff"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/$REPO/$BRANCH/.claude/commands"
TARGET="$HOME/.claude/commands"

echo "Installing Claude Code handoff commands..."

mkdir -p "$TARGET"

curl -fsSL "$BASE_URL/handoff.md" -o "$TARGET/handoff.md"
curl -fsSL "$BASE_URL/handoff-update.md" -o "$TARGET/handoff-update.md"

echo ""
echo "Done. Commands available globally in Claude Code:"
echo "  /handoff         — create a new HANDOFF.md"
echo "  /handoff-update  — update an existing HANDOFF.md"