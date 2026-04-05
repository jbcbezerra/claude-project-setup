# Onboard Agent Workflow

Follow this workflow at the start of a new session or when picking up a repo for the first time.

## When to use

- First time working in this repository
- Starting a new session after a long break
- Picking up work started by another agent or session

## Steps

### 1. Read the contract

Read `CLAUDE.md` at the repo root. This is the operating contract — it defines priorities, tone, verification loop, and git policy.

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

Look in `.agent-brain/tasks/` for in-progress plans or task breakdowns. If there are active tasks:
- Read the plan
- Ask the user if they want to continue this work or start something new

### 6. Check inbox

Scan `.agent-brain/inbox/` for items the user may have dropped since the last session. If relevant to the current task, read them. If not, mention their existence.

### 7. Load task-relevant knowledge

Based on what the user asks you to do:
- Read applicable `rules/` files
- Read applicable `patterns/` files
- Read applicable `knowledge/` files

Only read what's relevant to the task — don't load the entire brain.

## Done when

- You understand the project architecture and stack
- You know what rules and patterns apply to your task area
- You've checked for in-progress work and inbox items
- You're ready to start the task
