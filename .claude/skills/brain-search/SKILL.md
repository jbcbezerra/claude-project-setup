---
description: "Search across all .agent-brain/ files by content, not just titles. Usage: /brain-search <query>"
user_invocable: true
args: query
---

# /brain-search

Search across all `.agent-brain/` files for relevant content. Goes deeper than scanning `REGISTRY.md` titles — searches inside file bodies.

## Input

The user provides a search query:

```
/brain-search authentication
/brain-search how do we handle errors
/brain-search date formatting
/brain-search retry policy
```

## Steps

### 1. Check brain exists

If `.agent-brain/` does not exist:
```
No .agent-brain/ found. Run /brain-init to bootstrap.
```
And stop.

### 2. Search strategy

Perform a multi-pass search:

**Pass 1 — Registry scan (always first)**
Read `REGISTRY.md` and find entries whose title or description matches the query. This is fast and often sufficient.

**Pass 2 — Content grep**
Search inside all `.agent-brain/**/*.md` files for the query terms:

```bash
grep -r -l -i "<query>" .agent-brain/ --include="*.md"
```

For multi-word queries, also search for individual keywords to catch partial matches.

**Pass 3 — Semantic scan (only if passes 1-2 return < 3 results)**
Read the files that partially matched and score them by relevance:
- Exact phrase match → high relevance
- All keywords present → medium relevance
- Some keywords present → low relevance
- Title/heading match → boost relevance

### 3. Rank results

Sort results by:
1. Relevance score (exact match > keyword match > partial match)
2. Tier (tier-2 files rank above tier-3 files for lookup queries)
3. Recency (more recently modified files rank higher for ties)

### 4. Present results

Output a concise ranked list:

```
Found 5 results for "error handling":

1. rules/error-handling.md — Error handling conventions (exact match)
   "Always use catchError operator, never empty catch blocks..."

2. decisions/ADR-20260403-error-strategy.md — Why we centralized error handling
   "Context: scattered try-catch blocks with no logging..."

3. knowledge/api-error-codes.md — External API error code reference
   "The payments API returns 429 for rate limiting..."

4. patterns/service.md — Standard service pattern (mentions error handling)
   "...catchError(this.handleError)..."

5. log/20260403-error-handling-tasks.md — Session log (historical)
   "Migrated 42 files to centralized error handling..."
```

Show:
- File path and title
- Why it matched (exact match, keyword, partial)
- A one-line excerpt showing the matching context
- Maximum 10 results (truncate with "... and N more")

### 5. Offer next actions

Based on results, suggest:
- "Read `<top-result>` for the full details?"
- If no results: "No matches found. Try broader keywords, or check if this knowledge should be captured with `/brain-capture`."

## Scaling note

`/brain-search` searches `.agent-brain/` files only (typically < 100 files), not the full codebase. No subagents needed — always runs inline.
