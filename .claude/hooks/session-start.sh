#!/bin/bash
# SessionStart hook — auto-onboard the agent by reading tier-1 context
# Triggered: every time a new Claude Code session starts in this repo

BRAIN_DIR=".agent-brain"

# Skip if no brain exists
if [ ! -d "$BRAIN_DIR" ]; then
  echo "No .agent-brain/ found. Run /brain-init to bootstrap."
  exit 0
fi

echo "=== Agent Brain: Session Start ==="

# Check for unprocessed inbox items
INBOX_COUNT=$(find "$BRAIN_DIR/inbox" -name "*.md" 2>/dev/null | wc -l)
if [ "$INBOX_COUNT" -gt 0 ]; then
  echo "Inbox: $INBOX_COUNT unprocessed item(s) — run /brain-promote to organize"
fi

# Check for active tasks
TASK_COUNT=$(find "$BRAIN_DIR/tasks" -name "*.md" 2>/dev/null | wc -l)
if [ "$TASK_COUNT" -gt 0 ]; then
  echo "Active tasks: $TASK_COUNT — check .agent-brain/tasks/ for in-progress work"
fi

# Check context staleness (warn if older than 30 days)
if [ -f "$BRAIN_DIR/context/stack.md" ]; then
  if [ "$(uname)" = "Darwin" ]; then
    LAST_MOD=$(stat -f %m "$BRAIN_DIR/context/stack.md")
  else
    LAST_MOD=$(stat -c %Y "$BRAIN_DIR/context/stack.md")
  fi
  NOW=$(date +%s)
  AGE_DAYS=$(( (NOW - LAST_MOD) / 86400 ))
  if [ "$AGE_DAYS" -gt 30 ]; then
    echo "Warning: context/stack.md is ${AGE_DAYS} days old — run /brain-refresh"
  fi
fi

echo "=== Read REGISTRY.md + context/ to orient ==="
