---
description: "Quick capture — classify and file a learning, convention, decision, or gotcha into .agent-brain/. Usage: /brain-capture <text>"
user_invocable: true
args: text
---

# /brain-capture

Capture a piece of knowledge from the conversation and persist it in `.agent-brain/`.

## Input

The user provides free-text describing something worth remembering. Examples:

```
/brain-capture we use Day.js instead of Moment for bundle size — all dates go through DateUtilService
/brain-capture never use raw SQL queries — always use the query builder
/brain-capture the auth flow redirects through /callback because the IdP requires a registered redirect URI
/brain-capture npm run test:prod hangs if the dev server is running on the same port
```

## Steps

### 1. Classify

Analyze the input and classify it into exactly one category:

| Category | Signal words / patterns | Destination |
|----------|------------------------|-------------|
| **rule** | "always", "never", "must", "don't", conventions, constraints | `rules/<topic>.md` |
| **pattern** | code structure, skeleton, template, "looks like", "shaped like" | `patterns/<topic>.md` |
| **decision** | "we chose", "decided", "because", trade-offs, alternatives rejected | `decisions/ADR-YYYYMMDD-<topic>.md` |
| **knowledge** | domain logic, business rules, API behavior, "how X works" | `knowledge/<topic>.md` |
| **command** | terminal commands, flags, timeouts, "run with", "hangs if" | `commands/<topic>.md` |
| **workflow** | multi-step procedures, "first do X, then Y", migration steps | `workflows/<topic>.md` |

### 2. Confidence check

Rate classification confidence 0.0-1.0:
- **>= 0.7** — proceed
- **< 0.7** — ask the user: "This sounds like it could be a [category A] or [category B]. Which fits better?"

### 3. Check for existing files

Search `REGISTRY.md` and the target folder for existing files on the same topic.
- If a related file exists → **update it** (append or merge) rather than creating a new file.
- If no related file exists → create a new one.

### 4. Write the file

Use the appropriate template based on category:

**Rule:**
```markdown
# <Rule Title>

<What to do, with code examples showing the correct way>

## Anti-patterns

<What NOT to do, with counter-examples>
```

**Decision (ADR):**
```markdown
# ADR-YYYYMMDD: <Title>

## Status
Accepted

## Context
<What prompted the decision — extracted from user input>

## Decision
<What was chosen and why>

## Consequences
<Trade-offs, follow-up work — infer from context or mark as TODO>
```

**Knowledge:**
```markdown
# <Title>

<Structured explanation of the concept, behavior, or domain rule>

## Details
<Supporting information, edge cases, examples>
```

**Command:**
```markdown
# <Topic>

## Command
<the exact command>

## Flags
<important flags and when to use them>

## Gotchas
<failure modes, hangs, conflicts>
```

**Workflow:**
```markdown
# <Workflow Title>

## When to use
<trigger condition>

## Steps
1. <step>
2. <step>
...
```

**Pattern:** For patterns, ask the user to use `/brain-extract <file>` instead, as patterns are best mined from real code. Only create a pattern file directly if the user insists or provides a code skeleton in the capture text.

### 5. Update REGISTRY.md

Add a one-line entry under the appropriate section header. Format:
```
- [Title](folder/filename.md) — one-line description
```

### 6. Confirm

Output:
- What was created or updated
- The file path
- A one-line summary of what was captured

## Scaling note

`/brain-capture` processes a single piece of text — it does not scan the codebase. No subagents needed. Always runs inline.
