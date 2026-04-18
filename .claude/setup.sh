#!/bin/bash
# claude-project-setup bootstrap helper (monorepo variant).
# /plugin commands run inside Claude Code, not the shell — this script
# prints them, waits for confirmation, creates the marker file, and then
# walks you through the monorepo-specific setup (rename directories, etc.).

set -e

echo "=== claude-project-setup setup (monorepo variant) ==="
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

# ---------------------------------------------------------------------------
# Sanity checks on the current directory
# ---------------------------------------------------------------------------
if [ ! -d ".agent-brain" ]; then
  echo "⚠ .agent-brain/ not found in $(pwd). Copy it from this template into your repo root."
fi

MISSING_FE=0
MISSING_BE=0
[ -f "frontend/CLAUDE.md" ] || MISSING_FE=1
[ -f "backend/CLAUDE.md" ]  || MISSING_BE=1

if [ "$MISSING_FE" -eq 1 ] || [ "$MISSING_BE" -eq 1 ]; then
  echo ""
  echo "⚠ Per-app CLAUDE.md files not found:"
  [ "$MISSING_FE" -eq 1 ] && echo "   - frontend/CLAUDE.md (missing)"
  [ "$MISSING_BE" -eq 1 ] && echo "   - backend/CLAUDE.md (missing)"
  echo "   Copy them from this template into your repo root."
fi

# ---------------------------------------------------------------------------
# Optional: rename frontend/backend directories
# ---------------------------------------------------------------------------
rename_brain_namespace() {
  # $1 = old name (e.g. "frontend"), $2 = new name (e.g. "web")
  local old="$1"
  local new="$2"
  for parent in rules patterns knowledge; do
    if [ -d ".agent-brain/$parent/$old" ]; then
      if command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1; then
        git mv ".agent-brain/$parent/$old" ".agent-brain/$parent/$new" 2>/dev/null \
          || mv ".agent-brain/$parent/$old" ".agent-brain/$parent/$new"
      else
        mv ".agent-brain/$parent/$old" ".agent-brain/$parent/$new"
      fi
      echo "  ↪ renamed .agent-brain/$parent/$old → .agent-brain/$parent/$new"
    fi
  done
}

echo ""
read -r -p "Are your directory names different from 'frontend' / 'backend'? [y/N] " RENAME
if [[ "$RENAME" =~ ^[Yy]$ ]]; then
  read -r -p "  New name for 'frontend' (ENTER to keep): " FE_NEW
  read -r -p "  New name for 'backend' (ENTER to keep):  " BE_NEW

  if [ -n "$FE_NEW" ] && [ "$FE_NEW" != "frontend" ]; then
    if [ -d "frontend" ]; then
      if command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1; then
        git mv frontend "$FE_NEW" 2>/dev/null || mv frontend "$FE_NEW"
      else
        mv frontend "$FE_NEW"
      fi
      echo "✓ frontend/ → $FE_NEW/"
    fi
    rename_brain_namespace "frontend" "$FE_NEW"
    echo "  ⚠ Also update REGISTRY.md section headings and references in the two per-app CLAUDE.md files."
  fi

  if [ -n "$BE_NEW" ] && [ "$BE_NEW" != "backend" ]; then
    if [ -d "backend" ]; then
      if command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1; then
        git mv backend "$BE_NEW" 2>/dev/null || mv backend "$BE_NEW"
      else
        mv backend "$BE_NEW"
      fi
      echo "✓ backend/ → $BE_NEW/"
    fi
    rename_brain_namespace "backend" "$BE_NEW"
    echo "  ⚠ Also update REGISTRY.md section headings and references in the two per-app CLAUDE.md files."
  fi
fi

# ---------------------------------------------------------------------------
# Next steps
# ---------------------------------------------------------------------------
echo ""
echo "Next steps:"
echo "  1. Fill the Project table in CLAUDE.md (root)."
echo "  2. Fill the Stack table in each per-app CLAUDE.md."
echo "  3. In Claude Code, run /brain-init to auto-detect both stacks and seed context/."
