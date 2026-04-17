# AGENT.md

**Purpose**: This is the primary, self-contained operating contract for the coding agent in this project. All agent executions in this repository must follow this structure strictly.

---

## 1. Mission and Priorities

For every task, optimize in this order:
1. **Correctness and Safety**: Ensure the code works and doesn't break existing functionality.
2. **Best-Practice Maintainability**: Determine the best-practice approach and keep everything highly maintainable by default (clear architecture, readability, and long-term supportability).
3. **Minimal, Understandable Changes**: Targeted edits. No scope creep, no undocumented changes, and no speculative refactors.
4. **Verification**: Always validate changes (tests, lint, build) when relevant.
5. **Speed & Efficiency**: Keep execution lean.
6. **Security**: NEVER hardcode secrets, API keys, or passwords. ALWAYS use environment variables. If you encounter exposed secrets in the code, warn the user immediately. Do not print `.env` file contents in the chat.

---

## 2. Tone & Style

- **Be concise and direct.** Do not use filler words, pleasantries, or apologies.
- **No "I will now..." or "Here is the code..."** Just provide the solution, the plan, or the code.
- **Fail fast.** If a request is ambiguous, lacks necessary context, or requires a destructive action you are unsure about, **STOP** and ask the user for clarification. Do not guess or hallucinate requirements.

---

## 3. Core Workflow (Mandatory)

### A. Context Understanding
Before making any changes:
- **Search Over Reading**: Prefer using your native codebase search tools or semantic search to find specific variables, usages, or functions. Avoid reading entire large files into context unless you need to understand the holistic logic.
- **Search Before Writing**: Before implementing a new utility function, component, or configuration, search the codebase to see if it or something similar already exists.
- Read project documentation in `.agents/knowledge/` and look up tech-stack specifics in `.agents/skills/`.
- Read relevant local rules in `.agents/rules/`.
- Inspect only the files necessary for the task.
- Review existing architecture and conventions. Do not deviate unless explicitly requested.

### B. Planning Layer
- **In-Chat Default**: Keep planning in-chat. If a task is small, execute directly. If large, provide a short step-by-step plan in-chat first.
- **Explicit Plans**: ONLY if the user explicitly requests a written plan (e.g., "create a plan"), generate it in `.agents/tasks/<YYYYMMDD>-<task>/plan.md`. If a plan is requested, **do not** implement anything until the user approves the plan.

### C. Implementation Layer
- Make minimal, targeted edits.
- Default to maintainable best-practice implementations unless the user requests a different trade-off (e.g., quick prototype).
- Keep functions and modules cohesive. Follow the existing architectural patterns.
- Add comments only where logic is non-obvious.
- **Test-Driven Modification**: Ensure baseline tests exist before touching existing logic, and write tests for new features to prove they work as requested. If tests are missing, ask the user if you should create baseline tests first, or if you should proceed with alternative verification.
- **Explicit Linter/Formatter Alignment**: Match the surrounding code style strictly (e.g., quotes, trailing commas, indentation) and respect the project's linter/formatter configurations.
- **Anti Happy-Path (Robust Error Handling)**: Explicitly handle edge cases, network timeouts, null values, or unexpected JSON schemas instead of assuming the happy path.
- **Zero-Dependency Preference**: Do not install new third-party dependencies/packages unless explicitly requested by the user. Prefer native standard library solutions. If a new dependency is absolutely required, ask for permission first.
- **Modernization Strategy**: Follow the "Complete First, Modernize Later" methodology. Do not rewrite or refactor code silently. Any modernization (e.g., migrating to newer syntax) should only happen after the core task is complete and verified.

### D. Validation
Run the smallest relevant checks. Check `package.json`, `Makefile`, or `.agents/commands/` for the exact testing and linting scripts:
- Type-check, lint, or format edited code paths.
- Run unit/integration tests touching the changed behavior.
- If the execution environment prevents validation, state clearly what was not run and why in your final response.
- **The 3-Strike Rule**: If a test, build, or command fails 3 times in a row, **STOP**. Do not blindly retry or apply speculative fixes. Explain the root cause to the user, show the error, and ask for guidance.

#### Verification Loop (Mandatory after any code change)
After completing implementation, run **at least** the following steps **in order**. All three must pass before a task is considered done. If any step fails, fix the issue and restart the loop from step 1.

1. **Format**: Run prettier on **only the changed files** — never on the entire project:
   ```bash
   npx prettier --write <changed-file-1> <changed-file-2> ...
   ```
   Do NOT run `npm run prettier` — it formats the entire `src/app/` directory, which touches files unrelated to the task and pollutes diffs.

2. **Test**: Run the production test suite:
   ```bash
   npm run test:prod
   ```
   All tests must pass. If tests fail, fix the root cause (do not skip or disable tests).

3. **Build**: Run the production build:
   ```bash
   npm run build:prod
   ```
   The build must complete with zero errors.

If any step fails, fix the issue and re-run the full loop (format → test → build). Do not skip steps or run them out of order.

### E. Definition of Done & Reporting
A task is considered complete when:
1. The code implements the requested feature/fix.
2. Existing tests pass (or new tests are added and pass).
3. The codebase lints and compiles successfully.
4. **No Leftover Debugging**: All debug artifacts (e.g., `console.log`, `print`, `debugger`) have been completely removed.
5. (If applicable) `.agents/commands/` or `.agents/knowledge/` have been updated.

The final response must clearly and concisely state:
- What files changed.
- How it was validated.
- Any remaining risks or follow-ups.

### F. Git & Version Control
- **git-svn project**: This repository is managed via `git svn`. The source of truth is the remote SVN server. The local git repo is a bridge only.
- **NO REMOTE CHANGES**: NEVER run `git svn dcommit`, `git push`, `git svn rebase`, or any command that reads from or writes to the remote SVN/git server. All operations must be strictly local.
- **NO WORKTREE COMMITS**: Subagents running in git worktrees must NOT create git commits. Worktree branches are temporary merge vehicles — commits on them could leak into SVN history via `dcommit`. Subagents should leave changes as uncommitted working-tree modifications only.
- Do not commit changes unless explicitly requested by the user.
- If requested to commit, always use Conventional Commits (e.g., `feat:`, `fix:`, `refactor:`, `docs:`).
- Keep commits atomic; do not bundle unrelated changes into a single commit.

---

## 4. Documentation & Artifact Policy

To prevent bloat, **do not automatically generate recurring logs, handoffs, or prompt files** for every task.

Create persistent artifacts **ONLY** when:
- Behavior, API, or architecture changed materially.
- Setup or runbook steps changed.
- The user explicitly asks for documentation.

When persistent documentation is needed:
- All project documentation lives in `.agents/knowledge/`. Do not use a separate `docs/` folder. Prefer updating existing documentation over creating new files.
- For architectural decisions, use `.agents/decisions/ADR-<YYYYMMDD>-<topic>.md`.
- Ensure all created documentation uses clear, descriptive names. Avoid minute-level timestamps unless explicitly requested.
- **Mandatory Registry Update**: Whenever ANY new asset is created in the `.agents/` folder (rules, skills, knowledge, commands, decisions, etc.), you MUST immediately update `.agents/registry.md` to index the new asset.

---

## 5. Command Execution & Runbooks

To avoid getting stuck on the same terminal commands, the agent must persist and reuse command knowledge:

- **Look Up Before Running**: Always check `.agents/commands/` before running complex builds, tests, servers, or deployment commands to verify the correct arguments and expected wait times.
- **Document Failures and Hangs**: If an executed command hangs, times out, requires interactive input handling, or fails repeatedly, you **MUST** document the correct usage in `.agents/commands/<topic>.md`.
- **Include Execution Details**: Documented commands must include:
  - The exact command string.
  - Required flags to bypass interactivity (e.g., `--no-interaction`, `-y`).
  - Expected execution duration (so future agents know how long to wait / `block_until_ms`).
  - What to do if the command hangs, and how to verify its success.

---

## 6. Project Directory Structure

Use `.agents/` as the canonical and exclusive folder for maintainable agent support material and all project documentation.

**Bootstrap Requirement (Mandatory):**
- When initializing `.agents/` in a repository, the agent MUST create the full canonical directory scaffold and create a `README.md` starter file inside each immediate subfolder (`rules`, `skills`, `workflows`, `knowledge`, `commands`, `context`, `decisions`, `tasks`) describing what belongs there.
- The agent MUST ensure `.agents/registry.md` indexes those README files and any newly created assets.

```text
./AGENT.md              # Project-specific operating contract (this file)
./.agents/
  registry.md           # Local index of project assets (MUST be updated when new files are added)
  rules/                # Project constraints, naming conventions, and forbidden patterns
  skills/               # Framework-specific knowledge (e.g., "React 18 Server Components rules")
  workflows/            # Project procedures and migration playbooks
  knowledge/            # Strictly for Business Logic, Domain rules, and external API documentation
  commands/             # Persistent terminal commands, expected wait times, and execution troubleshooting
  context/              # Strictly for Repo Setup, Tech Stack overview, and Global Architecture
  decisions/            # Project ADRs: ADR-YYYYMMDD-<topic>.md
  tasks/                # Optional persisted artifacts: YYYYMMDD-<task>/
```

---

## 7. Failure Policy

If the agent skips layers, ignores project rules, bloats the repository with unrequested documentation, attempts remote Git operations, fails to update `registry.md`, or acts out of scope, the execution is considered invalid and must be corrected immediately.
