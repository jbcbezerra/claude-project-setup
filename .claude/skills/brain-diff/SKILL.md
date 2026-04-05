---
description: "Show what changed in the brain since a date or commit. Usage: /brain-diff [since] (e.g., /brain-diff 7d, /brain-diff 2026-03-01, /brain-diff abc1234)"
user_invocable: true
args: since
---

# /brain-diff

Show what changed in `.agent-brain/` since a given point in time. Useful for code reviews, auditing brain growth, and understanding what knowledge was added or changed.

## Input

The user provides a time reference:

```
/brain-diff 7d                    # last 7 days
/brain-diff 30d                   # last 30 days
/brain-diff 2026-03-01            # since a specific date
/brain-diff abc1234               # since a specific commit
/brain-diff last-session          # since the last handoff/log entry
```

If no argument: default to 7 days.

## Steps

### 1. Resolve time reference

| Input | Resolved to |
|-------|-------------|
| `Nd` (e.g., `7d`) | `git log --since="N days ago"` |
| `YYYY-MM-DD` | `git log --since="YYYY-MM-DD"` |
| commit hash | `git log <hash>..HEAD` |
| `last-session` | Find most recent file in `.agent-brain/log/`, use its date |

### 2. Get brain changes from git

```bash
git log --since="<resolved>" --name-status --format="%H %ai %s" -- .agent-brain/
```

Categorize changes:
- **A** (added) — new brain files
- **M** (modified) — updated brain files
- **D** (deleted) — removed brain files
- **R** (renamed) — moved/renamed brain files

### 3. Analyze changes

For each changed file:

**Added files:**
- Read the file and summarize in one line
- Classify by type (rule, pattern, decision, knowledge, etc.)

**Modified files:**
- Run `git diff <since>..HEAD -- <file>` to see what changed
- Summarize the diff in one line (e.g., "added new anti-pattern example", "updated dependency versions")

**Deleted files:**
- Note what was removed and check if REGISTRY.md was updated accordingly

### 4. Present the diff

Output a structured summary:

```
Brain changes since 2026-03-28 (7 days):

Added (3):
  + rules/retry-policy.md — Never retry on 4xx errors, only 5xx
  + decisions/ADR-20260402-redis.md — Chose Redis over Memcached for pub/sub
  + patterns/api-handler.md — Standard API handler skeleton

Modified (2):
  ~ context/stack.md — Added zod@3.22, bumped react 18.2 → 18.3
  ~ rules/error-handling.md — Added catchError operator examples

Deleted (1):
  - patterns/old-widget.md — Removed deprecated widget pattern

Unchanged: 18 files

Summary: 3 added, 2 modified, 1 deleted, 18 unchanged
Growth: 23 → 25 brain files (+2 net)
```

### 5. Offer insights

Based on the diff, offer observations:
- "3 new rules added but 0 patterns — consider mining patterns with /brain-extract"
- "context/ files unchanged for 30+ days — consider /brain-refresh"
- "2 ADRs added — the project is making active architectural decisions"
- If deletions found: verify REGISTRY.md was cleaned up

## Scaling note

`/brain-diff` reads git history for `.agent-brain/` only (typically small). No subagents needed — always runs inline.
