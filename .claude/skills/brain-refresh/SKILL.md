---
description: Update .agent-brain/context/ files from the current codebase state — detects stack changes, new deps, updated commands.
user_invocable: true
---

# /brain-refresh

Re-scan the codebase and update `.agent-brain/context/` files to reflect the current state.

## Steps

### 1. Check brain exists

If `.agent-brain/context/` does not exist or is empty:
```
No context files found. Run /brain-init first.
```
And stop.

### 2. Scale assessment

Assess parallelization need based on brain size and codebase size:

| Conditions | Strategy |
|-----------|----------|
| Few context files + small repo (< 200 source files) | Inline — do everything sequentially |
| Multiple context files OR medium repo (200-2,000) | Launch 2 subagents: one re-detects project state (deps, commands, config), the other checks patterns for drift |
| Large repo (2,000+) OR many patterns (10+) | Launch 3 subagents: project state detection, pattern drift check (split by partition if 15+ patterns), architecture structure scan |

Subagents return structured diffs. The coordinator merges them, presents changes, and applies after approval.

Each subagent returns:
```
file_checked: <path>
changes:
  - field: <what changed>
    old: <previous value>
    new: <current value>
    confidence: <0.0-1.0>
drift:
  - pattern: <pattern name>
    source_file: <path>
    status: <current | drifted | orphaned>
    details: <what changed>
```

### 3. Re-detect project state

Scan the same config files as `/brain-init`:
- `package.json`, `tsconfig.json`, `angular.json`, `next.config.*`, `vite.config.*`
- `Cargo.toml`, `go.mod`, `pyproject.toml`, `setup.py`, `requirements.txt`
- `pom.xml`, `build.gradle`, `Gemfile`, `composer.json`
- `Makefile`, `Dockerfile`, `docker-compose.yml`
- `.editorconfig`, linter/formatter configs

Extract current:
- Dependencies and their versions
- Build / test / lint / format commands
- Framework version
- New or removed config files

### 4. Diff against existing context

Read current `context/stack.md` and `context/setup.md`. Compare:

| Aspect | Current context | Detected now | Action |
|--------|----------------|--------------|--------|
| Dependencies | listed in stack.md | from config files | add new, flag removed |
| Versions | listed in stack.md | from config files | update changed |
| Commands | listed in setup.md | from config/scripts | update changed |
| New config files | not mentioned | detected | note for user |

### 5. Check patterns for drift

For each file in `patterns/`:
1. Read the "Derived from" section to find the source file(s)
2. If the source file still exists, read it and compare structure against the pattern
3. If structure has diverged significantly → flag as **drifted**
4. If the source file was deleted → flag as **orphaned pattern**

**For large repos with many patterns:** Subagents each check a partition of patterns against the codebase. The coordinator merges drift findings.

### 6. Present changes

Show the user a diff-style summary:

```
context/stack.md:
  + Added: zod@3.22 (new dependency)
  ~ Updated: react 18.2 → 18.3
  - Removed: moment (no longer in package.json)

context/setup.md:
  ~ Test command changed: vitest → vitest run --reporter=verbose
  + New script: npm run db:migrate

patterns/:
  ! Drifted: patterns/component.md (source file structure changed)
  ? Orphaned: patterns/middleware.md (source file deleted)

Scale: 2 subagents used
```

Ask: "Apply these updates?"

### 7. Apply

For each approved change:
1. Update the context file in-place
2. For drifted patterns → offer to re-extract with `/brain-extract`
3. For orphaned patterns → offer to archive or delete
4. Update `REGISTRY.md` if files were added or removed

### 8. Update CLAUDE.md Project table

If the Project table in `CLAUDE.md` has stale values (wrong build command, outdated stack), offer to update it.

### 9. Report

Output:
- Files updated
- Dependencies added / removed / version-bumped
- Commands changed
- Patterns flagged for review
- Subagents used: N (if any)
- Suggested follow-ups
