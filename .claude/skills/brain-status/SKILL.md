---
description: Health check for .agent-brain/ — finds dead links, orphan files, stale content, and unprocessed inbox items.
user_invocable: true
---

# /brain-status

Run a health check on `.agent-brain/` and report the results.

## Steps

### 1. Check brain exists

If `.agent-brain/` does not exist, output:
```
No .agent-brain/ found. Run /brain-init to bootstrap.
```
And stop.

### 2. Scale assessment

Count the total files in `.agent-brain/` and the source files in the repo:

| Brain files + source files | Strategy |
|---------------------------|----------|
| < 300 total | Inline — run all checks sequentially |
| 300 — 2,000 | Launch 2 subagents: one checks registry consistency + staleness, the other scans the codebase for pattern/rule relevance |
| 2,000+ | Launch 3 subagents: registry consistency, staleness + coverage, codebase relevance scan |

Subagents return structured findings. The coordinator merges them into the final report.

### 3. Registry consistency

Read `REGISTRY.md`. For each entry:
- Verify the linked file exists. If not → report as **dead link**.

Then scan all `.md` files in `.agent-brain/` (excluding `REGISTRY.md`). For each file:
- Check if it has a corresponding entry in `REGISTRY.md`. If not → report as **orphan**.

### 4. Staleness check

For each file in `REGISTRY.md`, check the last modified date (via `git log -1 --format=%ci -- <file>` or filesystem mtime).

Flag as **stale** if:
- `context/` files: modified > 30 days ago
- `rules/` or `patterns/` files: modified > 60 days ago
- `decisions/` files: never stale (they're historical records)
- `knowledge/` files: modified > 90 days ago

### 5. Coverage counts

Count files per folder:

| Folder | Count |
|--------|-------|
| context/ | N |
| rules/ | N |
| patterns/ | N |
| decisions/ | N |
| knowledge/ | N |
| workflows/ | N |
| commands/ | N |
| specs/ | N |
| tasks/ | N |
| log/ | N |
| inbox/ | N |

### 6. Inbox check

List any files in `inbox/`. If non-empty, suggest running `/brain-promote`.

### 7. Structure check

Verify all expected directories exist:
`context/`, `rules/`, `patterns/`, `decisions/`, `knowledge/`, `workflows/`, `commands/`, `specs/`, `tasks/`, `log/`, `inbox/`

Report any missing directories.

### 8. Output report

Format the report concisely:

```
Brain health for <project-name>
================================

Coverage: 4 rules, 2 patterns, 3 ADRs, 1 knowledge, 2 commands
Inbox: 2 unprocessed items
Scale: <inline | N subagents used>

Issues:
  - Dead link: rules/old-rule.md (in REGISTRY.md but file missing)
  - Orphan: knowledge/auth-flow.md (file exists but not in REGISTRY.md)
  - Stale: context/stack.md (last modified 45 days ago)
  - Missing directory: workflows/

Suggestions:
  - Run /brain-promote to process 2 inbox items
  - Update context/stack.md or run /brain-refresh
  - Add knowledge/auth-flow.md to REGISTRY.md
```

Keep the output short. Only show sections that have findings.
