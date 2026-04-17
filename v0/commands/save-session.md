# Save Session History

Persist a pointer to this Claude session's brain files so a future agent can reload the full context.

**Argument:** A short kebab-case title for the session (e.g., `api-migration-setup`, `fix-auth-flow`, `refactor-tree-component`).

---

## Steps

### 1. Determine the session brain paths

The Claude project brain directory lives at:
```
~/.claude/projects/<project-dir-name>/
```

Where `<project-dir-name>` is derived from the current working directory by replacing `/` and `.` with `-`.

Find the **most recently modified `.jsonl` file** in that directory — that is the current session's transcript. Extract the session UUID from the filename (the part before `.jsonl`).

The session paths are:
- **Transcript:** `~/.claude/projects/<project-dir-name>/<session-uuid>.jsonl`
- **Working directory:** `~/.claude/projects/<project-dir-name>/<session-uuid>/` (may not exist if no subagents or cached tool results were created)

Verify both paths exist. The transcript must exist; the working directory is optional.

### 2. Summarize the session

Look back at the conversation to extract:
- **Goal:** What was the user trying to accomplish? (1-2 sentences)
- **Key decisions:** What conventions, patterns, or approaches were agreed upon?
- **What was created/modified:** List the key output files from this session

### 3. Write the history file

Create the file at `.agents/history/<YYYYMMDD>-<title>.md` using today's date and the argument `$ARGUMENTS` as the title.

Use this template:

```markdown
# Session: <Human-readable title>

**Date:** <YYYY-MM-DD>
**Goal:** <1-2 sentence summary>

---

## Claude Session Brain

### Session transcript
- `<absolute path to .jsonl>`

### Session working directory
- `<absolute path to session UUID directory>` (or "No working directory for this session" if it doesn't exist)

---

## Summary

<What was accomplished, what was decided, what files were created/modified>

---

## Key Decisions

- <Decision 1>
- <Decision 2>
- ...
```

### 4. Update the registry

Add an entry to `.agents/registry.md` under the `## History` section:
```
- [<YYYYMMDD> <Title>](history/<YYYYMMDD>-<title>.md) — <One-line summary>
```

If no `## History` section exists, create it.

### 5. Confirm

Tell the user the file was saved and print the path.
