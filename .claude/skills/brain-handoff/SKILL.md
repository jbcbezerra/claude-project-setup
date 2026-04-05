---
description: Save current session context for the next session to pick up seamlessly. Creates a structured handoff file in .agent-brain/tasks/.
user_invocable: true
---

# /brain-handoff

Save the current session's context, progress, and next steps so another session (or the same user later) can continue exactly where this one left off.

## Steps

### 1. Gather session context

Analyze the current session to extract:

**What was worked on:**
- Files modified (from git diff or session memory)
- Features built, bugs fixed, refactors done
- The user's original request / goal

**What's done:**
- Completed items with verification status (tests pass? build clean?)
- Decisions made during the session (and why)
- New brain files created (rules, patterns, ADRs captured)

**What's NOT done:**
- Remaining work from the original request
- Known issues or blockers encountered
- Things that were deferred or descoped

**Key context the next session needs:**
- Non-obvious gotchas discovered ("the tests hang if you run them with --watch")
- Relationships between files that aren't obvious from code alone
- Conventions or patterns established during this session
- Things that were tried and didn't work (so the next session doesn't repeat them)

### 2. Check for existing handoff

Look in `.agent-brain/tasks/` for an existing task/handoff related to the same work:
- If found → update it rather than creating a duplicate
- If not found → create a new one

### 3. Write handoff file

Create `.agent-brain/tasks/YYYYMMDD-<topic>/handoff.md`:

```markdown
# Handoff: <Brief Title>

## Status
In Progress | Blocked | Ready for Review

## Goal
<The original request / what we're trying to achieve>

## Completed
- <what was done, with file paths>
- <verification status: tests pass / build clean / untested>

## Remaining
- [ ] <next step — be specific enough that the next session can act immediately>
- [ ] <next step>
- [ ] <next step>

## Decisions Made
- <decision and why — so the next session doesn't re-debate it>

## Gotchas
- <non-obvious things the next session needs to know>
- <things that were tried and failed>

## Key Files
- `path/to/file.ts` — <what role this file plays>
- `path/to/other.ts` — <why it matters>

## Brain Updates
- <any rules/patterns/ADRs created during this session>

## How to Continue
<specific instructions for the next session — what to read first, what to do first>
```

### 4. Update REGISTRY.md

Add entry under `## Tasks`:
```
- [Handoff: <Title>](tasks/YYYYMMDD-<topic>/handoff.md) — <status>, <remaining count> items left
```

### 5. Offer brain-capture

Review the session for knowledge that should be persisted beyond this handoff:
- If a non-obvious gotcha was discovered → offer to `/brain-capture` it as a rule or command
- If a new code pattern was established → offer to `/brain-extract` it
- If a technical decision was made → offer to capture it as an ADR

These are separate from the handoff — they persist as long-term brain knowledge, while the handoff is temporary and gets archived when the work is done.

### 6. Confirm

Output:
- Handoff file path
- Summary: N completed, N remaining, status
- Any brain-capture suggestions

## Scaling note

`/brain-handoff` summarizes the current session — no codebase scanning needed. Always runs inline.
