#!/bin/bash
# claude-project-setup bootstrap helper.
# /plugin commands run inside Claude Code, not the shell — this script
# prints them, waits for confirmation, then creates the marker file.

set -e

echo "=== claude-project-setup setup ==="
echo ""
echo "1. In Claude Code, run these commands:"
echo "   /plugin marketplace add thedotmack/claude-mem"
echo "   /plugin install claude-mem"
echo "   /plugin install superpowers@claude-plugins-official"
echo "   /reload-plugins"
echo ""
read -r -p "Press ENTER once you've completed the above..."

mkdir -p "$HOME/.claude"
touch "$HOME/.claude/.claude-project-setup-plugins-ok"
echo "✓ Created marker: $HOME/.claude/.claude-project-setup-plugins-ok"

if [ ! -d ".agent-brain" ]; then
  echo "⚠ .agent-brain/ not found in $(pwd). Copy it from this template into your repo root."
fi

echo ""
echo "Now run /brain-init in Claude Code to bootstrap context for your stack."
