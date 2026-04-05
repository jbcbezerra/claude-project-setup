#!/bin/bash
# PostToolUse hook — nudge agent to consider brain-capture after Write/Edit operations
# Triggered: after Write or Edit tool use on source files (not .agent-brain/ files)

# Only process source file edits, not brain file edits
CHANGED_FILE="${CLAUDE_TOOL_ARG_FILE_PATH:-${CLAUDE_TOOL_ARG_file_path:-}}"

# Skip if no file path (shouldn't happen but be safe)
if [ -z "$CHANGED_FILE" ]; then
  exit 0
fi

# Skip brain files — don't nudge when updating the brain itself
case "$CHANGED_FILE" in
  *.agent-brain/*|*.claude/*) exit 0 ;;
esac

# Skip test files, configs, and generated files
case "$CHANGED_FILE" in
  *.test.*|*.spec.*|*_test.*|*_spec.*) exit 0 ;;
  package.json|package-lock.json|yarn.lock|*.lock) exit 0 ;;
  *.config.*|*.json|*.yml|*.yaml|*.toml) exit 0 ;;
esac

# Count edits in this session (track via temp file)
SESSION_COUNTER="/tmp/agent-brain-edit-count-$$"
if [ -f "$SESSION_COUNTER" ]; then
  COUNT=$(cat "$SESSION_COUNTER")
else
  COUNT=0
fi
COUNT=$((COUNT + 1))
echo "$COUNT" > "$SESSION_COUNTER"

# Only nudge every 10 edits to avoid noise
if [ $((COUNT % 10)) -eq 0 ]; then
  echo "Tip: ${COUNT} files edited this session. If you encountered gotchas or established new patterns, consider /brain-capture to persist them."
fi
