# New Feature Area Workflow

Run this workflow when adding a new module, domain area, or significant feature to the codebase.

## When to use

- Adding a new top-level module or domain (e.g., `src/payments/`, `src/notifications/`)
- Creating a new microservice or package in a monorepo
- Building a new major feature that introduces new conventions

## Steps

### 1. Check existing patterns

Read `REGISTRY.md` and review relevant patterns:
- Which existing patterns apply to this feature area?
- Does the project have a standard directory structure for features?

```
Read .agent-brain/REGISTRY.md
Read applicable patterns from .agent-brain/patterns/
```

### 2. Scaffold the feature

Create the directory structure following existing project conventions:
- Follow the established module/feature layout
- Use the naming conventions documented in `rules/`
- Copy structure from `patterns/` when creating new files

### 3. Assess convention gaps

As you build, note if the new feature introduces anything not covered by existing brain files:

| Situation | Action |
|-----------|--------|
| New file type not in patterns (e.g., first WebSocket handler) | Run `/brain-extract` after creating the first good example |
| New convention needed (e.g., event naming) | Run `/brain-capture` to document the convention as a rule |
| Non-obvious architectural choice | Create an ADR in `decisions/` |

### 4. Update architecture

Update `.agent-brain/context/architecture.md`:
- Add the new module/directory to the system map
- Document how it connects to existing modules
- Note any new data flows or dependencies

### 5. Update REGISTRY.md

Add entries for any new brain files created during this workflow.

## Done when

- Feature area is scaffolded following existing patterns
- Any new conventions are captured in rules or patterns
- Architecture docs reflect the new module
- No orphan brain files (everything in REGISTRY.md)
