# Parallel Subagent Migration — Lessons Learned

Tips for running multiple api-migration (or similar) subagents in parallel using worktree isolation.

---

## 1. Group related APIs into a single agent

APIs that share many consumer files must go to the **same agent**. Otherwise each agent edits its own slice of a shared file, producing conflicting diffs that require manual merge.

**Example:** The 4 metrics APIs (`metrics-configuration`, `metrics-graph`, `metrics-rule`, `metrics-alerts`) share ~10 Angular components in `src/app/argos/`. Migrating them in 4 separate agents caused 7 conflicting files. They should have been one agent.

**How to check before dispatching:** Grep for all consumers of the APIs you plan to parallelize. If two APIs share 3+ consumer files, assign them to the same agent.

## 2. Copy new (untracked) files — not just diffs

`git diff HEAD` only captures modifications to tracked files. New service files created by subagents are **untracked** and won't appear in the diff. After applying diffs, always check each worktree for untracked files:

```bash
cd /path/to/worktree && git status --short | grep "^?"
```

Then `cp -r` any new directories/files into the main tree.

## 3. api.module.ts is always a conflict

Every migration removes an import+provider from `src/app/api/manual/api.module.ts`. When running N agents in parallel, apply all diffs **excluding** this file, then edit it once manually to remove all N entries.

## 4. Cross-agent dependency blindness

Agent A may change a shared service's return type (e.g., `Promise` → `Observable`). Agent B, working from the same base, doesn't see this change and generates incompatible code. After merging, look for:

- `.then()` called on what is now an `Observable`
- `await` on an `Observable` without `lastValueFrom()`
- Constructor injection where `inject()` was introduced by another agent

## 5. Recommended batch size and grouping

- **5-7 independent agents** is a sweet spot for parallel migrations
- Group by domain overlap, not alphabetically
- Reserve 1 "shared infrastructure" agent for APIs that touch the same components
- Always verify with `ng build --aot` once after merging all agents

## 6. git-svn constraint

This is a git-svn project. Subagents must **never commit** in worktrees. Worktree branches are disposable — only the uncommitted working-tree changes matter. See `AGENT.md` section F for the full policy.
