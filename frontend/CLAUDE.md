# Frontend (app-specific)

> Inherits from the repo-root `CLAUDE.md`. This file adds frontend-only context.
> When Claude Code edits a file under `frontend/`, both files are loaded.

---

## Stack

<!-- Fill per-project -->

| Field   | Value                               |
|---------|-------------------------------------|
| Stack   | `<framework, language, runtime>`    |
| Dev     | `<dev-server command>`              |
| Build   | `<build command>`                   |
| Test    | `<test command>`                    |
| Lint    | `<lint command>`                    |
| Format  | `<format command>`                  |

All commands are expected to run from this directory (`frontend/`) unless noted.

---

## Verification Loop

Run from `frontend/`. Order matters — all must pass before the change is done:

1. **Format** changed files only
2. **Lint** changed files only — auto-fix, then error on the rest
3. **Test** — all tests pass
4. **Build** — zero errors

If any step fails, fix and restart from step 1.

---

## Brain Subfolders

Frontend-scoped knowledge lives in namespaced subfolders of the shared `.agent-brain/` at the repo root:

- Rules: `.agent-brain/rules/frontend/`
- Patterns: `.agent-brain/patterns/frontend/`
- Knowledge: `.agent-brain/knowledge/frontend/`

Shared constraints (VCS, secrets, cross-cutting style) live in `.agent-brain/rules/shared/`.
ADRs and workflows are project-wide — no frontend/backend split.

---

## If this directory is renamed

If you renamed this directory (e.g., `frontend` → `web`), also update:

1. The `.agent-brain/rules/frontend/`, `patterns/frontend/`, `knowledge/frontend/` subfolders to match
2. The brain-subfolder paths at the top of this file
3. The "Layout" row in the repo-root `CLAUDE.md`
4. Any references in `.agent-brain/REGISTRY.md` section headings

`.claude/setup.sh` automates this when you answer **yes** to the rename prompt.
