# Onboard Agent Workflow

Follow this workflow at the start of a new session or when picking up a repo for the first time.

## When to use

- First time working in this repository
- Starting a new session after a long break
- Picking up work started by another agent or session

## Steps

### 1. Read the contract

Read `CLAUDE.md` at the repo root. This is the operating contract — it defines priorities, tone, verification loop, and git policy.

**Monorepo check:** if `frontend/CLAUDE.md` and/or `backend/CLAUDE.md` exist, also read the one(s) that match your task area. Claude Code will load them automatically when editing files under their subtrees, but reading them upfront surfaces per-app build/test/lint commands before you start work.

### 2. Read tier-1 context

Read all files in `.agent-brain/context/`:
- `architecture.md` — system design, module boundaries
- `stack.md` — frameworks, versions, dependencies
- `setup.md` — how to install, run, test, build

These give you the minimum context to orient in the codebase.

### 3. Scan the registry

Read `.agent-brain/REGISTRY.md` to see what knowledge is available. Don't read everything — just build a mental index of what exists and where.

### 4. Check brain health

Run `/brain-status` to verify the brain is current:
- Are there dead links or orphan files?
- Is anything stale?
- Are there unprocessed inbox items?

If issues are found, mention them to the user but don't block on fixing them unless they affect the current task.

### 5. Check active work

Look in `.agent-brain/tasks/` and `.agent-brain/specs/` for in-progress plans or design specs. If there are active tasks:
- Read the plan or spec
- If a superpowers plan exists, use `superpowers:executing-plans` to continue
- Ask the user if they want to continue this work or start something new

### 6. Check inbox

Scan `.agent-brain/inbox/` for items the user may have dropped since the last session. If relevant to the current task, read them. If not, mention their existence.

### 7. Load task-relevant knowledge

Based on what the user asks you to do:
- Read applicable `rules/` files — in a monorepo, start with `rules/shared/`, then add `rules/frontend/` or `rules/backend/` depending on where the task lives.
- Read applicable `patterns/` files — use the app-matching subfolder (`patterns/frontend/` or `patterns/backend/`).
- Read applicable `knowledge/` files — `knowledge/shared/` for cross-cutting domain, plus the app-matching subfolder.

Only read what's relevant to the task — don't load the entire brain.

### 8. Plugin awareness

This project uses superpowers and claude-mem plugins:
- Use `claude-mem:smart-explore` for token-efficient code navigation (AST-based)
- Use `superpowers:brainstorming` before creating new features
- Use `superpowers:systematic-debugging` when hitting issues
- Use `superpowers:verification-before-completion` before claiming work is done

## Done when

- You understand the project architecture and stack
- You know what rules and patterns apply to your task area
- You've checked for in-progress work and inbox items
- You're aware of available plugin skills
- You're ready to start the task
