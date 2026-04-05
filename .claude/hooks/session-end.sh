#!/bin/bash
# Stop hook — suggest saving session summary if material work was done
# Triggered: when the Claude Code session ends

BRAIN_DIR=".agent-brain"

# Skip if no brain exists
if [ ! -d "$BRAIN_DIR" ]; then
  exit 0
fi

# Check if any source files were modified during this session
# (git tracks this even without commits)
CHANGED=$(git diff --name-only 2>/dev/null | wc -l)
STAGED=$(git diff --cached --name-only 2>/dev/null | wc -l)
TOTAL=$((CHANGED + STAGED))

if [ "$TOTAL" -gt 3 ]; then
  echo "=== Agent Brain: Session End ==="
  echo "${TOTAL} files changed this session."
  echo "Consider running /brain-handoff to save context for the next session."
fi
