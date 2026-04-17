# Agent Brain

A persistent knowledge system for coding agents. Drop it into any repo and give Claude Code structured memory that survives across sessions.

Git-tracked markdown files organized into three tiers: **onramp** (read every session), **lookup** (read when relevant), and **write-back** (agent outputs). Skills automate maintenance, agents audit for drift, workflows guide multi-step operations. All skills and agents **auto-scale** — they assess repo size and spawn subagents in parallel for large codebases.

**Integrates with plugins:** Works alongside `superpowers` (TDD, debugging, planning) and `claude-mem` (cross-session memory, AST exploration). Brain skills handle project knowledge; plugins handle development workflow.

---

## Quick Start

1. Copy `CLAUDE.md`, `.claude/`, and `.agent-brain/` into your repo root
2. Fill in the Project table at the top of `CLAUDE.md`
3. Run `/brain-init` to auto-detect your stack and seed context + patterns

```
/brain-init
```

That's it. The brain is live.

---

## Directory Structure

```
your-repo/
├── CLAUDE.md                    # Operating contract — priorities, workflow, git policy
├── .claude/
│   ├── settings.json            # Hook configuration (auto-onboard, nudge, session-end)
│   ├── hooks/                   # Shell scripts triggered by Claude Code events
│   │   ├── session-start.sh     #   SessionStart — auto-read context, check inbox/tasks
│   │   ├── post-edit-nudge.sh   #   PostToolUse — nudge to /brain-capture after edits
│   │   └── session-end.sh       #   Stop — suggest /brain-handoff if material work done
│   ├── reference/
│   │   └── scaling-strategy.md  #   Shared auto-scaling reference for all skills/agents
│   ├── skills/                  # Slash commands for brain maintenance
│   │   ├── brain-init/          #   /brain-init — bootstrap a new repo
│   │   ├── brain-capture/       #   /brain-capture — quick-capture learnings
│   │   ├── brain-status/        #   /brain-status — health check
│   │   ├── brain-extract/       #   /brain-extract — mine patterns from code
│   │   ├── brain-promote/       #   /brain-promote — process inbox items
│   │   ├── brain-refresh/       #   /brain-refresh — update context from codebase
│   │   ├── brain-search/        #   /brain-search — full-text search across brain files
│   │   ├── brain-handoff/       #   /brain-handoff — save session context for next session
│   │   ├── brain-prune/         #   /brain-prune — fix issues flagged by /brain-status
│   │   └── brain-diff/          #   /brain-diff — show brain changes since a date
│   └── agents/                  # Autonomous subagents
│       ├── brain-audit.md       #   Audit rules/patterns against actual code
│       ├── pattern-miner.md     #   Discover patterns from file clusters
│       ├── test-pattern-miner.md#   Discover test patterns from test files
│       └── context-farmer.md    #   Farm git history for context updates
└── .agent-brain/                # The brain itself
    ├── REGISTRY.md              # Index of everything
    ├── .gitignore               # Excludes farmer state, temp files
    ├── context/                 # Tier 1: project architecture, stack, setup
    ├── rules/                   # Tier 2: coding constraints
    ├── patterns/                # Tier 2: code templates to copy from
    ├── decisions/               # Tier 2: ADRs
    ├── knowledge/               # Tier 2: domain logic, business rules
    ├── workflows/               # Tier 2: multi-step playbooks
    ├── commands/                # Tier 2: terminal command reference
    ├── specs/                   # Tier 3: design specs (from superpowers:brainstorming)
    ├── tasks/                   # Tier 3: implementation plans + handoffs
    ├── log/                     # Tier 3: execution summaries
    └── inbox/                   # Tier 3: user drop zone
```

---

## Skills

Skills are slash commands you invoke in Claude Code. They handle brain maintenance so you don't have to edit files manually.

### `/brain-init`

Bootstrap `.agent-brain/` in a new repo.

```
/brain-init
```

What it does:
- Creates the full directory scaffold
- Detects your stack from config files (`package.json`, `Cargo.toml`, `go.mod`, etc.)
- Generates `context/setup.md` (install, run, test, build commands)
- Generates `context/stack.md` (frameworks, versions, key deps)
- Creates a starter `context/architecture.md` from your directory structure
- Seeds 1-3 pattern files from recurring code structures it finds
- Populates `REGISTRY.md`

Run this once when adding Agent Brain to a repo. If `.agent-brain/` already exists, it offers to rebuild or fill gaps.

---

### `/brain-capture <text>`

Quick-capture a learning mid-session.

```
/brain-capture never use raw SQL — always go through the query builder
/brain-capture we chose Redis over Memcached for pub/sub support
/brain-capture the /callback endpoint exists because the IdP requires a registered redirect URI
/brain-capture npm test hangs if the dev server is running on the same port
```

What it does:
- Classifies your input as a rule, decision, knowledge, command, or workflow
- If uncertain, asks you to clarify
- Checks for existing files on the same topic (updates instead of duplicating)
- Creates the file with the correct template format
- Updates `REGISTRY.md`

This is the fastest way to persist something worth remembering. Use it whenever a gotcha, convention, or decision surfaces in conversation.

---

### `/brain-status`

Health check for the brain.

```
/brain-status
```

Output looks like:
```
Brain health for my-project
================================

Coverage: 4 rules, 2 patterns, 3 ADRs, 1 knowledge, 2 commands
Inbox: 2 unprocessed items

Issues:
  - Dead link: rules/old-rule.md (in REGISTRY.md but file missing)
  - Orphan: knowledge/auth-flow.md (file exists but not in REGISTRY.md)
  - Stale: context/stack.md (last modified 45 days ago)

Suggestions:
  - Run /brain-promote to process 2 inbox items
  - Update context/stack.md or run /brain-refresh
```

Run this at the start of a session or whenever you want to check brain hygiene.

---

### `/brain-extract <file-or-glob>`

Mine a reusable pattern from existing code.

```
/brain-extract src/services/user.service.ts
/brain-extract src/components/Button.tsx
/brain-extract "src/api/*.py"
/brain-extract src/handlers/order_handler.go
```

What it does:
- Reads the file(s) and identifies the structural skeleton
- Strips business logic, keeps the shape (imports, DI, lifecycle, public API)
- If given a glob with multiple files, finds the common structure across all
- Writes a pattern template to `patterns/` with "When to use" and "Variations"
- Tracks which source file(s) the pattern was derived from

This is the highest-leverage skill. Patterns are the #1 thing that makes agents produce consistent code. Mine them from your best code.

---

### `/brain-promote`

Process items from the inbox.

```
/brain-promote
```

What it does:
- Lists all files in `inbox/`
- For each: reads content, classifies, proposes a destination (rule, knowledge, decision, etc.)
- Shows the plan and asks for confirmation
- Transforms content into the target format (adds ADR sections, anti-pattern sections, etc.)
- Moves files to the correct tier-2 folder
- Updates `REGISTRY.md`

Use this after dumping raw notes, meeting summaries, or research into `inbox/`. The two-step flow (dump now, organize later) matches how people actually work.

---

### `/brain-refresh`

Update context files from the current codebase state.

```
/brain-refresh
```

What it does:
- Re-scans config files for dependency and command changes
- Diffs against `context/stack.md` and `context/setup.md`
- Shows what changed and asks for approval before applying
- Checks patterns for drift (source files changed since pattern was written)
- Optionally updates the `CLAUDE.md` Project table

Run this after dependency upgrades, migrations, or any change that affects the project structure.

---

### `/brain-search <query>`

Full-text search across all brain files.

```
/brain-search authentication
/brain-search retry policy
/brain-search how do we handle errors
```

What it does:
- Scans `REGISTRY.md` titles first (fast pass)
- Greps inside all `.agent-brain/` file contents (deep pass)
- Ranks results by relevance: exact match > keyword match > partial match
- Shows file path, match reason, and a one-line excerpt

Essential once the brain grows past 20+ files. Faster than manually scanning the registry.

---

### `/brain-handoff`

Save session context for the next session to continue seamlessly.

```
/brain-handoff
```

What it does:
- Summarizes what was worked on, what's done, what's left
- Records decisions made and gotchas discovered
- Lists key files involved
- Writes a structured handoff to `tasks/YYYYMMDD-<topic>/handoff.md`
- Offers to `/brain-capture` any learnings that should be permanent

The difference from `log/`: logs are retrospective ("here's what happened"), handoffs are forward-looking ("here's how to continue").

---

### `/brain-prune`

Fix the issues flagged by `/brain-status`. Where status diagnoses, prune acts.

```
/brain-prune
```

What it does:
- Removes dead links from `REGISTRY.md`
- Indexes orphan files or offers to delete them
- Archives stale content
- Merges duplicate files covering the same topic
- Updates superseded ADR statuses
- Shows the full action plan and asks for approval before executing

---

### `/brain-diff [since]`

Show what changed in the brain since a date, commit, or time period.

```
/brain-diff 7d
/brain-diff 2026-03-01
/brain-diff abc1234
/brain-diff last-session
```

What it does:
- Queries git history for `.agent-brain/` changes only
- Categorizes: added, modified, deleted, renamed
- Summarizes each change in one line
- Reports net brain growth (files before → after)
- Offers insights ("3 rules added but 0 patterns — consider /brain-extract")

Useful for code reviews and auditing brain growth over time.

---

## Agents

Agents are autonomous subagents that run independently. They read the codebase, do analysis, and write results to `.agent-brain/`.

### brain-audit

Audits the brain against the actual codebase.

```
Trigger the brain-audit agent to scan for rule violations and pattern drift
```

What it checks:
- **Rules**: greps the codebase for violations of each rule in `rules/`
- **Patterns**: checks if real code still matches documented patterns in `patterns/`
- **Decisions**: verifies ADR assertions still hold (e.g., "we use Day.js" — is Moment still imported?)
- **Context**: checks if `stack.md` matches actual dependency versions

Writes a report to `.agent-brain/log/YYYYMMDD-brain-audit.md`. The agent is read-only on source code — it never modifies application files.

---

### pattern-miner

Discovers patterns you didn't know you had.

```
Run the pattern-miner agent on src/services/
```

What it does:
- Scans the target directory for source files
- Clusters files by structural similarity (imports, declarations, lifecycle)
- Extracts the common skeleton from each cluster (3+ files minimum)
- Writes candidates to `inbox/` for human review

Candidates go to `inbox/`, not directly to `patterns/` — you review and promote them with `/brain-promote`. Especially valuable in large or legacy codebases where conventions exist implicitly.

---

### test-pattern-miner

Discovers test patterns — the dedicated sibling of pattern-miner for test files.

```
Run the test-pattern-miner agent on src/__tests__/
Run the test-pattern-miner agent on tests/
```

What it does:
- Scans test files (`.test.*`, `.spec.*`, `test_*.*`, etc.)
- Identifies test framework, setup/teardown patterns, mocking style, assertion conventions
- Clusters tests by structural similarity (separate unit / integration / e2e)
- Flags test anti-patterns (no assertions, order-dependent tests, missing cleanup)
- Writes candidates to `inbox/` for review

The general pattern-miner skips tests by design. This agent fills that gap — test structure consistency matters just as much as source code consistency.

---

### context-farmer

Keeps context files current by farming git history.

```
Run the context-farmer agent
```

What it does:
- Reads commits since its last run (or last 14 days on first run)
- Identifies material changes: new deps, removed modules, renamed directories, config changes
- Updates `context/stack.md`, `context/architecture.md`, and `context/setup.md`
- Flags ADRs that may be superseded
- Writes findings that need human review to `inbox/`

Tracks its own state in `.agent-brain/log/.context-farmer-last-run` so it only processes new commits each time.

---

## Hooks

Hooks make the brain self-maintaining. They fire automatically on Claude Code events — no manual invocation needed. Configured in `.claude/settings.json`.

| Hook | Trigger | What it does |
|------|---------|-------------|
| **session-start.sh** | `SessionStart` | Checks for unprocessed inbox items, active tasks, and stale context. Reminds the agent to read tier-1 files. |
| **post-edit-nudge.sh** | `PostToolUse` (Write/Edit) | After every 10 source file edits, nudges: "Consider `/brain-capture` if you hit gotchas or established patterns." Skips brain files, tests, and configs. |
| **session-end.sh** | `Stop` | If 3+ files were changed, suggests: "Run `/brain-handoff` to save context for the next session." |

Hooks are lightweight shell scripts — they print reminders, they don't block. The agent sees the output and can act on it or ignore it.

---

## Workflows

Workflows are documented playbooks in `.agent-brain/workflows/`. They combine multiple skills and agents into a multi-step procedure for recurring situations.

### post-migration

**When**: After completing a large migration (library swap, framework upgrade, directory restructure).

Steps:
1. `/brain-refresh` — update context to reflect new state
2. `/brain-extract` — mine patterns from 2-3 exemplar files using the new approach
3. Archive or delete old patterns that reference the replaced approach
4. Create an ADR documenting the migration decision
5. Update or retire affected rules
6. `superpowers:verification-before-completion` — verify migration claims with evidence
7. Run `brain-audit` to verify no old-pattern remnants remain

### new-feature-area

**When**: Adding a new module or domain to the codebase.

**Prerequisite**: For major features, run `superpowers:brainstorming` first to create a design spec (saved to `.agent-brain/specs/`) and implementation plan.

Steps:
1. Review existing patterns that apply to the new area
2. Scaffold the feature following those patterns
3. If new conventions emerge, capture them with `/brain-capture` or `/brain-extract`
4. Update `context/architecture.md` with the new module

### onboard-agent

**When**: First session in a repo, or picking up after a long break.

Steps:
1. Read `CLAUDE.md` (operating contract)
2. Read all `context/` files (tier-1 onramp)
3. Scan `REGISTRY.md` to index what knowledge exists
4. Run `/brain-status` to check health
5. Check `tasks/` for in-progress work
6. Check `inbox/` for unprocessed items
7. Load task-relevant rules and patterns (tier-2 lookup)

---

## The Tier System

The brain is organized into three tiers based on *when* an agent reads them:

| Tier | When to read | Contents |
|------|-------------|----------|
| **1 — Onramp** | Every session start | `context/` — architecture, stack, setup |
| **2 — Lookup** | When relevant to the task | `rules/`, `patterns/`, `decisions/`, `knowledge/`, `workflows/`, `commands/` |
| **3 — Write-back** | Agent writes here | `specs/`, `tasks/`, `log/`, `inbox/` |

This prevents agents from wasting context window loading everything upfront. Tier-1 is always read. Tier-2 is pulled in selectively. Tier-3 is for outputs.

---

## Usage Patterns

### "I just learned something worth remembering"

```
/brain-capture <what you learned>
```

### "I wrote good code and want future agents to follow this pattern"

```
/brain-extract src/path/to/exemplar-file.ts
```

### "Someone dumped notes into inbox/ and I want to organize them"

```
/brain-promote
```

### "I haven't touched this repo in a while — is the brain still current?"

```
/brain-status
/brain-refresh
```

### "I just finished a big migration"

Follow the post-migration workflow in `.agent-brain/workflows/post-migration.md`.

### "Are my documented rules actually being followed?"

```
Run the brain-audit agent
```

### "I suspect there are patterns in this codebase nobody documented"

```
Run the pattern-miner agent on src/services/
```

### "I need to hand off my work to continue later"

```
/brain-handoff
```

### "I want to find something in the brain but don't know which file"

```
/brain-search <query>
```

### "The brain has issues — fix them"

```
/brain-prune
```

### "What changed in the brain this week?"

```
/brain-diff 7d
```

### "Are my tests consistent?"

```
Run the test-pattern-miner agent on tests/
```

### "I want to design a new feature" (with plugins)

```
superpowers:brainstorming
```

Then follow with `superpowers:writing-plans` → `superpowers:executing-plans`.

### "I need to explore unfamiliar code efficiently" (with plugins)

```
claude-mem:smart-explore
```

Uses AST parsing for 4-8x token savings vs reading full files.

### "I'm stuck on a bug" (with plugins)

```
superpowers:systematic-debugging
```

Enforces root cause investigation before proposing fixes.

### "My work is complete — what now?" (with plugins)

```
superpowers:finishing-a-development-branch
```

Handles merge/PR decisions and worktree cleanup.

---

## Plugin Integration

Agent Brain works alongside two complementary plugins:

| Plugin | Purpose | Integration |
|--------|---------|-------------|
| **superpowers** | Development workflow (TDD, debugging, planning, code review) | Specs → `.agent-brain/specs/`, Plans → `.agent-brain/tasks/` |
| **claude-mem** | Cross-session memory, AST exploration | Use `smart-explore` for token-efficient code navigation |

### Workflow

1. **Design**: `superpowers:brainstorming` → spec in `.agent-brain/specs/`
2. **Plan**: `superpowers:writing-plans` → plan in `.agent-brain/tasks/`
3. **Execute**: `superpowers:executing-plans` or `claude-mem:do`
4. **Capture**: `/brain-capture` for learnings, `/brain-handoff` for session continuity
5. **Extract**: `/brain-extract` + `new-feature-area` workflow for patterns

### First-Time Plugin Setup

```bash
# Add marketplace and install
/plugin marketplace add thedotmack/claude-mem
/plugin install claude-mem
/reload-plugins

# Verify
/plugin list
```

See `CLAUDE.md` → Required Plugins section for full setup instructions.

---

## Customizing for Your Project

1. **Fill in `CLAUDE.md`** — the Project table and Project-Specific Rules section
2. **Seed context** — `/brain-init` handles this, but review and expand the generated files
3. **Mine your best code** — run `/brain-extract` on 3-5 exemplar files to build your pattern library
4. **Capture as you go** — use `/brain-capture` whenever something non-obvious comes up
5. **Audit periodically** — run `brain-audit` and `/brain-status` to keep the brain honest

The brain improves with use. The more rules, patterns, and context it accumulates, the more consistent your agents become.

---

## Auto-Scaling

Every skill and agent automatically decides whether to use subagents and how many, based on the repo size. No configuration needed — it just measures and adapts.

### How it works

Before doing scan-heavy work, each skill/agent runs a scale assessment:

```bash
# Count source files (excluding generated dirs)
find . -type f \( -name "*.ts" -o -name "*.py" -o -name "*.go" -o ... \) \
  -not -path "*/node_modules/*" -not -path "*/dist/*" ... | wc -l
```

### Scaling tiers

| Tier | Source files | Subagents | Strategy |
|------|-------------|-----------|----------|
| **Inline** | < 200 | 0 | Everything runs sequentially in the main session |
| **Light** | 200 — 1,000 | 2-3 | Split by concern (rules vs patterns vs decisions) |
| **Heavy** | 1,000 — 5,000 | 3-5 | Split by directory partition |
| **Massive** | 5,000+ | 5-8 | One subagent per top-level domain directory |

### Which skills scale

| Skill / Agent | Scales? | What gets parallelized |
|--------------|---------|----------------------|
| `/brain-init` | Yes | Context generation + pattern seeding run in parallel |
| `/brain-capture` | No | Single text input — always inline |
| `/brain-status` | Yes | Registry checks + codebase relevance scan in parallel |
| `/brain-extract` | Yes | Multi-file analysis split across subagents |
| `/brain-promote` | Yes | Classification of many inbox items in parallel |
| `/brain-refresh` | Yes | Config re-detection + pattern drift check in parallel |
| `/brain-search` | No | Searches brain files only (< 100 files) — always inline |
| `/brain-handoff` | No | Summarizes current session — always inline |
| `/brain-prune` | Yes | Duplicate detection + staleness scan in parallel |
| `/brain-diff` | No | Queries git history for brain dir only — always inline |
| `brain-audit` | Yes | Rule/pattern/decision auditing across codebase partitions |
| `pattern-miner` | Yes | File fingerprinting across directory partitions |
| `test-pattern-miner` | Yes | Test file fingerprinting across directory partitions |
| `context-farmer` | Yes | Dependency + structural + ADR analysis in parallel |

### Coordination pattern

Subagents do **read-only analysis** and return structured results. The coordinator (main session) handles all writes — merging results, deduplicating, and writing to `.agent-brain/`. This prevents file conflicts and ensures registry consistency.

The full scaling strategy reference is at `.claude/reference/scaling-strategy.md`.
