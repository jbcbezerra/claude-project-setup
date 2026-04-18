# CLAUDE.md

> Operating contract for Claude Code. All agent behavior and knowledge lookup flows from this file.

---

## Project

> **Monorepo variant.** Per-app build/test/lint/format commands live in `frontend/CLAUDE.md` and `backend/CLAUDE.md` — Claude Code automatically merges those when you edit files under their subtrees.

<!-- Fill per-project -->

| Field          | Value                                                           |
|----------------|-----------------------------------------------------------------|
| **Name**       | `<project-name>`                                                |
| **Layout**     | Monorepo — `frontend/` + `backend/` (rename if needed; see `.claude/setup.sh`) |
| **Root build** | `<root-level build command, e.g. ./build.sh — or leave blank>`  |
| **Test**       | See `frontend/CLAUDE.md` and `backend/CLAUDE.md`                |
| **Lint**       | See `frontend/CLAUDE.md` and `backend/CLAUDE.md`                |
| **Format**     | See `frontend/CLAUDE.md` and `backend/CLAUDE.md`                |
| **VCS**        | `<git / git-svn / svn>`                                         |

---

## Required Plugins

This project uses plugins from external marketplaces. Team members must install them before contributing.

### Marketplaces

| Name | Source |
|------|--------|
| claude-mem | `thedotmack/claude-mem` (https://github.com/thedotmack/claude-mem) |
| claude-plugins-official | bundled with Claude Code (no marketplace add required) |

### Plugins

| Plugin | Marketplace | Purpose |
|--------|-------------|---------|
| claude-mem | claude-mem | Persistent cross-session memory and knowledge bases |
| superpowers | claude-plugins-official | Development workflow enforcement (TDD, debugging, planning, code review) |

### First-Time Setup

Run these commands once per machine:

```bash
# Add the third-party marketplace (only needed for claude-mem)
/plugin marketplace add thedotmack/claude-mem

# Install the required plugins
/plugin install claude-mem
/plugin install superpowers@claude-plugins-official

# Reload to apply
/reload-plugins
```

To verify: run `/plugin list` — you should see both `claude-mem` and `superpowers` as installed.

After setup, create the marker file to suppress the session reminder:
```bash
touch ~/.claude/.claude-project-setup-plugins-ok
```

---

## Priorities

1. **Correctness** — Code works. Nothing existing breaks.
2. **Maintainability** — Best-practice, readable, supportable.
3. **Minimal scope** — Targeted edits. No scope creep.
4. **Verification** — Format → test → build after every change.
5. **Security** — No hardcoded secrets. Warn if found.

Concise and direct. No filler. If ambiguous → ask.

---

## Agent Brain

`.agent-brain/` is the project's persistent memory. It survives across sessions, agents, and worktrees.

**Monorepo namespacing.** `rules/`, `patterns/`, and `knowledge/` are split into `shared/`, `frontend/`, `backend/` subfolders so per-app knowledge doesn't collide. `decisions/` (ADRs) and `workflows/` stay project-wide — they describe the whole system. There is still only one `.agent-brain/` at the repo root; the split is purely folder-level.

The brain has three tiers based on *when* an agent reads them:

```
.agent-brain/
│
│  REGISTRY.md              # Index of everything — read FIRST every session
│
│  ── TIER 1: ONRAMP (read on session start) ──────────────
│  context/                 # What is this project?
│    architecture.md        #   System design, module boundaries, data flow (both apps)
│    stack.md               #   Frameworks, versions — with ## Frontend / ## Backend sections
│    setup.md               #   Install, run, test, deploy — the agent README
│
│  ── TIER 2: LOOKUP (read when relevant to the task) ─────
│  rules/                   # Hard constraints — MUST follow
│    shared/                #   Project-wide (VCS, secrets, cross-cutting style)
│    frontend/              #   Frontend-only
│    backend/               #   Backend-only
│  patterns/                # Code templates — SHOULD copy structure from
│    frontend/              #   Frontend patterns
│    backend/               #   Backend patterns
│  decisions/               # ADRs — project-wide; not split
│  knowledge/               # Domain logic, business rules, external API docs
│    shared/                #   API contracts, shared types, domain model
│    frontend/              #   Frontend-only (UX conventions, component taxonomy)
│    backend/               #   Backend-only (data model, external service quirks)
│  workflows/               # Step-by-step playbooks — project-wide
│  commands/                # Terminal commands with flags, timeouts, gotchas
│
│  ── TIER 3: WRITE-BACK (agent writes during/after work) ─
│  specs/                   # Design specs from brainstorming: YYYYMMDD-<topic>-design.md
│  tasks/                   # Implementation plans and breakdowns: YYYYMMDD-<topic>/
│  log/                     # Execution summaries: what was done, what's left
│  inbox/                   # User-dumped raw input for the agent to process
```

### How the tiers work

**Tier 1 — Onramp.** Read `REGISTRY.md` + `context/` at the start of every session. This is the minimum context to orient in the codebase. These files should be concise enough to read in full.

**Tier 2 — Lookup.** Read on-demand when the current task touches a relevant area. Don't read all rules upfront — check `REGISTRY.md` to find which ones apply, then read those.

**Tier 3 — Write-back.** The agent writes here. Plans go to `tasks/`, post-execution summaries go to `log/`. `inbox/` is a drop zone where the user can dump unstructured input (meeting notes, screenshots, research, ideas) for the agent to read and optionally promote to a higher-tier location.

---

### Task Directory Structure

Simple tasks use a single file: `tasks/YYYYMMDD-topic.md`

Complex multi-phase tasks use a directory with subdirectories per phase:

```
tasks/YYYYMMDD-topic/
├── main-task.md                    # Master plan — links to all phases
├── inventory/                      # Optional: baseline data, analysis artifacts
├── prework/                        # Prerequisites before main phases
│   ├── 01-first-prereq/
│   │   ├── plan.md                 # What to do
│   │   └── handoffs/               # Session boundaries within this phase
│   │       ├── step-1.md
│   │       ├── step-2.md
│   │       └── complete.md
│   └── 02-second-prereq/
│       └── plan.md
└── phases/                         # Main execution phases
    ├── 01-phase-name/
    │   ├── plan.md
    │   └── handoffs/
    └── 02-phase-name/
        └── plan.md
```

**Conventions:**
- Zero-pad phase numbers (`01-`, `02-`) for sort order
- Each phase directory contains `plan.md` as the main file
- Handoffs go in `handoffs/` subdirectory within their phase
- `main-task.md` is the entry point — always read it first
- Only create `handoffs/` when a phase spans multiple sessions

---

### Registry

`REGISTRY.md` is the table of contents. One line per file, grouped by folder. **Every** new file must be indexed here immediately.

```markdown
## Context
- [Architecture](context/architecture.md) — Module boundaries, data flow (both apps)
- [Stack](context/stack.md) — Frameworks, versions, key dependencies
- [Setup](context/setup.md) — Install, run, test, deploy

## Rules — Shared
- [Secrets Handling](rules/shared/secrets.md) — Never commit, always use env

## Rules — Frontend
- [Component Naming](rules/frontend/naming.md) — File and component name rules

## Rules — Backend
- [Error Handling](rules/backend/error-handling.md) — How errors propagate through the stack

## Patterns — Frontend
- [Component](patterns/frontend/component.md) — Standard component skeleton

## Patterns — Backend
- [Service](patterns/backend/service.md) — Standard service/module skeleton

## Decisions
- [ADR-20260405: State Management](decisions/ADR-20260405-state-management.md) — Why we chose X over Y
```

---

### Rules vs Patterns — the key distinction

**Rules** say *what to do and what not to do*. They are constraints.

```markdown
# <Rule Title>

<What to do, with code examples showing the correct way>

## Anti-patterns

<What NOT to do, with counter-examples>
```

**Patterns** show *what the code should look like*. They are templates. The agent copies the structure and adapts it. This is the most high-leverage thing in the brain — it prevents the agent from inventing a new style every time.

```markdown
# <Pattern Title>

Use this skeleton when creating a new <component type>.

<full code template — a real file stripped of business logic,
 showing imports, structure, naming, exports>

## When to use
- <trigger condition, e.g. "any new module in src/services/">

## Variations
- <named variant with code diff>
```

The difference: a rule says "always use early returns." A pattern shows you the full file *with* early returns already wired in, plus the imports, the naming, the folder placement, the test structure — all in one glance.

---

### Decisions (ADRs)

```markdown
# ADR-YYYYMMDD: <Title>

## Status
Accepted | Superseded by ADR-XXXXXXXX

## Context
<What prompted the decision>

## Decision
<What we chose and why>

## Consequences
<Trade-offs, follow-up work>
```

---

### Commands

Terminal command reference. Prevents agents from rediscovering the same gotchas.

```markdown
# <Topic>

## Command
<the exact command>

## Flags
- <important flags and when to use them>

## Duration
<expected time>

## If it hangs
<how to diagnose and recover>

## Verify success
<what a successful run looks like>
```

---

### Inbox

The user can drop anything here — raw notes, screenshots, copy-pasted threads, research dumps. No format required. The agent should:
1. Read inbox files when referenced or when starting a related task.
2. Offer to promote structured content to the right tier (`rules/`, `knowledge/`, `decisions/`).
3. Never delete inbox files without asking.

---

## Workflow

### Before code

1. Read `REGISTRY.md`. Pull in relevant tier-2 files.
2. Search the codebase before writing new utilities.
3. Check `patterns/` for templates before creating new files.
4. Large tasks: plan in-chat first. Persist to `tasks/` only if asked.

### During code

- Minimal, targeted edits. Follow existing patterns.
- Match surrounding code style strictly.
- No new dependencies without permission.
- Comments only where logic is non-obvious.
- Remove all debug artifacts before finishing.

### After code — Verification Loop

Run in order. All must pass. If any fails, fix and restart from step 1.

1. **Format** changed files only (never the whole project)
2. **Lint** changed files only — auto-fix what it can, error on the rest
3. **Test** — all tests pass
4. **Build** — zero errors

Use the exact commands from the Project table above.
If the environment prevents validation, state what was skipped and why.

### 3-Strike Rule

Command fails 3 times → **stop**. Show the error, explain root cause, ask for guidance.

---

## VCS Policy

<!-- Adjust per-project. Examples for git and svn below. -->

- Do not commit unless explicitly asked.
- Conventional Commits: `feat:`, `fix:`, `refactor:`, `docs:`.
- Atomic commits — one concern each.
- Never force-push or skip hooks without explicit permission.
- **File renames/moves**: Always use VCS commands to preserve history:
  - Git: `git mv old_path new_path`
  - SVN: `svn mv old_path new_path`
  - Never use plain `mv` — it destroys VCS history.

---

## Knowledge Capture

When something is learned that future sessions would benefit from:

| Learned | Destination |
|---------|-------------|
| Coding constraint — cross-cutting | `rules/shared/<topic>.md` |
| Coding constraint — frontend only | `rules/frontend/<topic>.md` |
| Coding constraint — backend only | `rules/backend/<topic>.md` |
| Code skeleton — frontend | `patterns/frontend/<topic>.md` |
| Code skeleton — backend | `patterns/backend/<topic>.md` |
| System design insight | `context/architecture.md` |
| Non-obvious technical choice | `decisions/ADR-YYYYMMDD-<topic>.md` |
| Domain logic — shared across apps | `knowledge/shared/<topic>.md` |
| Domain logic — frontend only | `knowledge/frontend/<topic>.md` |
| Domain logic — backend only | `knowledge/backend/<topic>.md` |
| Recurring multi-step operation | `workflows/<topic>.md` |
| Tricky terminal command | `commands/<topic>.md` |
| Design spec (from brainstorming) | `specs/YYYYMMDD-<topic>-design.md` |
| Implementation plan | `tasks/YYYYMMDD-<topic>/` |
| Session summary | `log/YYYYMMDD-<topic>.md` |

Do not auto-generate docs for every task. Capture only when material changes happened or the user asks. Always update `REGISTRY.md` when adding files. Prefer updating existing files over creating new ones.

---

## Bootstrap

When initializing `.agent-brain/` in a new repo:

1. Create the full directory scaffold (all tiers, including `specs/`). For monorepos, create `rules/{shared,frontend,backend}`, `patterns/{frontend,backend}`, `knowledge/{shared,frontend,backend}`.
2. Create `REGISTRY.md` with empty section headers (monorepo-aware groupings).
3. Generate `context/setup.md` by inspecting project config files per app (`frontend/package.json`, `backend/go.mod`, `backend/pyproject.toml`, etc.) plus any root-level build script.
4. Generate `context/stack.md` with two sections (`## Frontend`, `## Backend`) auto-populated from each app's detected dependencies and framework versions.
5. Scan for existing conventions per app and seed 1-2 pattern files from real code — land them in the correct `patterns/{frontend,backend}/` namespace.
6. Ask the user what to populate next.

---

## Plugin Integration

This project uses three complementary systems:

| System | Purpose | Skills |
|--------|---------|--------|
| `.agent-brain/` | Persistent project knowledge | `/brain-*` skills |
| superpowers | Development workflow enforcement | TDD, debugging, review, planning |
| claude-mem | Cross-session memory + exploration | `smart-explore`, `mem-search`, etc. |

**Workflow integration:**
1. **Design:** `superpowers:brainstorming` → spec in `.agent-brain/specs/`
2. **Plan:** `superpowers:writing-plans` → plan in `.agent-brain/tasks/`
3. **Execute:** `superpowers:executing-plans` or `claude-mem:do`
4. **Capture:** `/brain-capture` for learnings, `/brain-handoff` for session continuity
5. **Extract:** `/brain-extract` + `new-feature-area` workflow for patterns

### Superpowers Location Override

Save specs and plans to `.agent-brain/` instead of `docs/superpowers/`:
- **Specs:** `.agent-brain/specs/YYYYMMDD-<topic>-design.md`
- **Plans (simple):** `.agent-brain/tasks/YYYYMMDD-<topic>.md`
- **Plans (complex):** `.agent-brain/tasks/YYYYMMDD-<topic>/main-task.md`

---

## Project-Specific Rules

<!-- This is the ONLY section that changes per-project.
     Point to rule/pattern files or add inline rules here.

     Examples:

     Services must follow:
     - `.agent-brain/rules/service-conventions.md`
     - `.agent-brain/patterns/service.md`

     All database queries must use the query builder, never raw SQL.

     git-svn project: never run git push, git svn dcommit, or any remote operation.
-->
