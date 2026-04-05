---
description: Clean up the brain — fix dead links, archive stale files, merge duplicates, retire superseded ADRs.
user_invocable: true
---

# /brain-prune

Act on the issues flagged by `/brain-status`. Where status diagnoses, prune fixes.

## Steps

### 1. Run diagnostics

Perform the same checks as `/brain-status` to get the current issue list:
- Dead links in REGISTRY.md
- Orphan files not in REGISTRY.md
- Stale files (past their freshness threshold)
- Duplicate or overlapping content
- Superseded ADRs still marked as "Accepted"

### 2. Scale assessment

| Issues found | Strategy |
|-------------|----------|
| < 5 | Inline — process sequentially |
| 5-15 | Launch 2 subagents: one handles registry fixes (dead links, orphans), the other scans for duplicates and staleness |
| 15+ | Launch 3 subagents: registry fixes, duplicate detection, staleness + ADR review |

Subagents return proposed actions. The coordinator presents them for approval and executes.

Each subagent returns:
```
actions:
  - type: fix_dead_link | index_orphan | archive_stale | merge_duplicate | retire_adr | delete
    target: <file path>
    description: <what to do>
    confidence: high | medium | low
    details: <supporting info>
```

### 3. Classify issues and propose actions

For each issue, determine the appropriate action:

**Dead links** (in REGISTRY.md but file missing):
- **Remove from REGISTRY.md** — the file is gone, clean up the reference

**Orphan files** (file exists but not in REGISTRY.md):
- **Index** — add to REGISTRY.md if the content is valid and useful
- **Archive** — move to `log/archived/` if outdated but worth keeping
- **Delete** — if clearly junk or superseded

**Stale files** (past freshness threshold):
- **Flag for refresh** — suggest running `/brain-refresh` for context files
- **Archive** — if the content is about a completed migration or resolved issue
- **Keep** — if the content is still accurate (update the timestamp)

**Duplicates** (two files covering the same topic):
- **Merge** — combine into one file, keeping the best parts of each
- **Keep both** — if they cover genuinely different aspects

**Superseded ADRs**:
- **Update status** — change "Accepted" to "Superseded by ADR-XXXXXXXX"
- **Keep the file** — ADRs are historical records, never delete them

### 4. Detect duplicates

Compare brain files for overlapping content:

1. Read all tier-2 files
2. Compare titles and key terms
3. Flag pairs with > 60% keyword overlap
4. For each pair, determine which is more complete/current

**For large brains (subagent-assisted):** Subagent reads all files in its assigned folders, builds a keyword index, and returns overlap pairs.

### 5. Present the plan

Show the user all proposed actions grouped by type:

```
Brain prune plan:

Dead links (2):
  - Remove: rules/old-naming.md (file deleted, clean registry)
  - Remove: patterns/deprecated-widget.md (file deleted, clean registry)

Orphans (1):
  - Index: knowledge/auth-flow.md → add to REGISTRY.md under Knowledge

Stale (2):
  - Archive: log/20260201-migration.md (90 days old, migration complete)
  - Flag: context/stack.md (45 days old) → run /brain-refresh

Duplicates (1):
  - Merge: rules/error-handling.md + rules/error-conventions.md
    → keep rules/error-handling.md, merge unique content from error-conventions.md

Superseded ADRs (1):
  - Update: ADR-20260301-moment-js.md → status: "Superseded by ADR-20260405-dayjs"

Total: 7 actions
```

Ask: "Proceed? You can skip any action by number."

### 6. Execute approved actions

For each approved action:
1. Perform the file operation (delete, move, merge, edit)
2. Update REGISTRY.md to reflect the change
3. For merges: write the combined file, delete the duplicate

### 7. Report

Output:
- Actions completed: N
- Actions skipped: N
- REGISTRY.md entries updated: N
- Brain file count: before → after
- Subagents used: N (if any)
