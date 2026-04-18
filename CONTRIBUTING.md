# Contributing

Thanks for improving `claude-project-setup`. This is a template repo — anything you change here propagates to every project that copies it.

> **Branch note.** This is the **monorepo variant** (frontend + backend). The single-repo version lives on `main`. When making changes that should apply to both, land them on `main` first, then forward-port to this branch.

## What this is

See [README.md](README.md) for the high-level overview. In short: this template ships an Agent Brain (`.agent-brain/`), the supporting `.claude/` skills/agents/hooks, an operating contract (`CLAUDE.md`), and **per-app stub `CLAUDE.md` files** under `frontend/` and `backend/`.

## Repo layout

| Path | What lives here |
|------|-----------------|
| `CLAUDE.md` | Operating contract. Edit cautiously — every adopter inherits this. |
| `frontend/CLAUDE.md` | Per-app stub — adopters fill Stack/build/test commands. Inherited up the tree when editing files under `frontend/`. |
| `backend/CLAUDE.md` | Same for the backend app. |
| `.claude/skills/<name>/SKILL.md` | Slash commands (e.g. `/brain-init`) |
| `.claude/agents/<name>.md` | Autonomous subagent specs |
| `.claude/hooks/*.sh` | Event-triggered shell scripts (wired in `settings.json`) |
| `.claude/reference/` | Shared docs referenced by multiple skills |
| `.claude/setup.sh` | Interactive bootstrap — plugin setup + optional rename of `frontend/`/`backend/` |
| `.claude/settings.json` | Hook + plugin configuration (committed) |
| `.claude/settings.local.json` | Per-user overrides (gitignored) |
| `.agent-brain/` | The brain scaffold — pre-namespaced with `rules/{shared,frontend,backend}`, `patterns/{frontend,backend}`, `knowledge/{shared,frontend,backend}`. `/brain-init` populates downstream. |

## Modifying skills

Each skill lives in `.claude/skills/<name>/SKILL.md` with this frontmatter:

```yaml
---
description: One-line description shown in skill listings.
user_invocable: true   # if invokable as a slash command
args: <arg-name>       # optional, if the skill takes input
---
```

Body is plain markdown — instructions the model reads on invocation. Keep skills focused (one verb each), and reuse `.claude/reference/scaling-strategy.md` for any scale-aware logic.

## Adding new skills or agents

1. Create the file under `.claude/skills/<name>/SKILL.md` or `.claude/agents/<name>.md`.
2. Use the existing files as templates — match the frontmatter shape.
3. Update `README.md` to document the new skill/agent.
4. If the skill writes to `.agent-brain/`, also update `.agent-brain/REGISTRY.md` template if it introduces a new section.

## Updating CLAUDE.md

Keep the operating contract concise. Project-specific guidance for downstream adopters belongs in `## Project-Specific Rules` (the template section at the bottom). Generic guidance for *all* adopters goes in the main body.

## Verification before PR

This is a docs/config template — no test suite. Before opening a PR, manually verify:

```bash
# JSON validity
python3 -c "import json; json.load(open('.claude/settings.json'))"

# Hooks still run
bash .claude/hooks/session-start.sh

# setup.sh syntax
bash -n .claude/setup.sh

# Per-app CLAUDE.md stubs present
ls frontend/CLAUDE.md backend/CLAUDE.md

# Namespaced brain scaffold intact
ls .agent-brain/rules/{shared,frontend,backend} \
   .agent-brain/patterns/{frontend,backend} \
   .agent-brain/knowledge/{shared,frontend,backend}

# Plugin docs are consistent across files
grep -rn "claude-mem\|superpowers" CLAUDE.md README.md .claude/settings.json
```

## Commit style

Follow Conventional Commits (matches `CLAUDE.md` VCS Policy):

- `feat:` new skill, agent, hook, or template feature
- `fix:` bug fix in a skill, hook, or doc
- `docs:` README / CLAUDE.md / CONTRIBUTING changes only
- `refactor:` internal restructuring without behavior change

Atomic commits. Use `git mv` for renames so history survives.
