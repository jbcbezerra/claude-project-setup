# Load Session Context

Rebuild the working context from a previous session's history file so you can continue that work.

**Argument:** The history filename (e.g., `20260403-batch-api-migration-15-endpoints`) or leave empty to list available sessions.

---

## Steps

### 1. Find the history file

If `$ARGUMENTS` is provided:
- Look for `.agents/history/$ARGUMENTS.md` (append `.md` if not already present)
- If not found, try a fuzzy match: list all `.md` files in `.agents/history/` and find the closest match

If `$ARGUMENTS` is empty or not provided:
- List all `.md` files in `.agents/history/` (excluding `README.md`), sorted by date descending
- Present them as a numbered list with their **Date** and **Goal** extracted from frontmatter
- Ask the user to pick one, then proceed with that file

### 2. Read the history file

Read the full history file. Extract and display to the user:
- **Session title and date**
- **Goal**
- **Summary** (if present)
- **Key Decisions** (if present)

### 3. Load all referenced context files

Read these project context files that any session would need:

1. `AGENT.md` — operating contract
2. `CLAUDE.md` — codebase instructions
3. `.agents/rules/` — read all rule files referenced or relevant to the session's domain
4. `.agents/knowledge/` — read any knowledge files relevant to the session's domain

Then look inside the history file for **explicit file references** — paths to workflows, rules, knowledge docs, task plans, or source files mentioned in the summary or key decisions. Read those too.

**Common patterns to look for:**
- `.agents/workflows/*.md` — migration playbooks, procedures
- `.agents/tasks/*/plan.md` — task plans referenced by the session
- `.agents/knowledge/*.md` — domain knowledge docs
- `.agents/context/*.md` — architecture and tech stack docs
- Source file paths mentioned in "Files created/modified" sections

### 4. Confirm context is loaded

Tell the user:
- Which session was loaded (title + date + goal)
- Which context files were read (as a short bullet list)
- A one-line suggestion of what to do next based on the session's goal

Then ask: "Ready to continue. What would you like to do?"
