---
description: Process .agent-brain/inbox/ items — classify, transform, and move to the appropriate tier-2 folder.
user_invocable: true
---

# /brain-promote

Process unstructured items from `.agent-brain/inbox/` and promote them to the correct tier-2 location.

## Steps

### 1. Scan inbox

List all files in `.agent-brain/inbox/`.

If empty:
```
Inbox is empty. Nothing to promote.
```
And stop.

### 2. Scale assessment

Count the number of inbox items:

| Inbox items | Strategy |
|-------------|----------|
| 1-3 | Inline — classify and transform sequentially |
| 4-8 | Launch 2 subagents, each classifying half the items. Coordinator reviews proposals, resolves conflicts, and writes files. |
| 9+ | Launch 3 subagents, each handling a third. Coordinator merges. |

Subagents do classification and transformation only — they return proposed actions. The coordinator handles all writes to avoid file conflicts.

Each subagent returns:
```
item: <filename>
classification: <category>
proposed_destination: <path>
proposed_content: <transformed markdown>
confidence: <0.0-1.0>
splits: [<if the item should become multiple files>]
```

### 3. Analyze each item

For each file in the inbox (inline or via subagent results):

1. Read the full content
2. Classify into one or more categories:

| Category | Destination | Signal |
|----------|-------------|--------|
| Rule | `rules/` | Conventions, constraints, "always/never" |
| Pattern | `patterns/` | Code skeletons, structural templates |
| Decision | `decisions/` | Why something was chosen, trade-offs |
| Knowledge | `knowledge/` | Domain logic, API docs, business rules |
| Command | `commands/` | Terminal commands, flags, gotchas |
| Workflow | `workflows/` | Multi-step procedures |
| Context | `context/` | Architecture, stack, setup info |
| Discard | (delete) | Outdated, irrelevant, or already captured |

3. If a single file contains multiple distinct topics → propose splitting it into separate files.

### 4. Present the plan

Show the user a table of proposed actions:

```
Inbox items: 3

1. inbox/meeting-notes-api.md
   → knowledge/api-rate-limits.md (API rate limit behavior)
   → rules/retry-policy.md (retry conventions extracted from notes)

2. inbox/slack-thread-auth.md
   → decisions/ADR-20260405-oauth-provider.md (OAuth provider choice)

3. inbox/old-todo.md
   → Discard (all items already completed)
```

Ask: "Proceed with this plan? You can adjust any item."

### 5. Execute

For each approved action:

1. **Transform** the content into the target format:
   - Rules → add `## Anti-patterns` section
   - Decisions → format as ADR with Status/Context/Decision/Consequences
   - Knowledge → structure with `## Details` section
   - Commands → add Flags/Duration/Gotchas sections
   - Patterns → ask user to use `/brain-extract` instead if raw code is provided

2. **Write** the new file to the target folder

3. **Update REGISTRY.md** with the new entry

4. **Remove** the inbox file (move, don't copy — the inbox should be empty after promotion)

### 6. Report

Output:
- Files promoted: N
- Files discarded: N
- Files remaining in inbox: N (if user skipped any)
- New REGISTRY.md entries added
- Subagents used: N (if any)
