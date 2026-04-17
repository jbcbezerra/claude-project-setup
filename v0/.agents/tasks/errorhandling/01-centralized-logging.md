# Centralized Logging — Eliminate Direct console.* Calls

## Context

21 production files contain ~60 direct `console.error`, `console.warn`, `console.debug`, `console.info`, and `console.log` calls that bypass the existing `LoggerService`. This accumulated over years of development. The result: no ability to control log verbosity at runtime, no single integration point for external monitoring, and no way to filter noise in production.

`LoggerService` already exists at `src/app/core/services/logger/logger.service.ts` with proper log levels (TRACE, DEBUG, INFO, WARN, ERROR, FATAL), sessionStorage persistence, and timer utilities. It simply isn't being used consistently.

**Note:** The original audit estimated 87+ files, but verification showed many were JSDoc examples (`object.ts`, `array.ts`), commented-out dead code (`tree-state.service.ts` `logTreeState()`), or test/cypress files. The real scope is significantly smaller.

---

## Decisions (from interview 2026-04-03)

### Pure utility functions — keep console.error, no DI threading

`src/app/core/utils/date.ts` (5 calls in `validateAndConvertDate()`) and `src/app/core/utils/uri.ts` (1 call in `decodeStateParams()`) are pure functions outside Angular's DI system. Options considered:

- **Logger parameter threading**: Rejected — every call site would need to pass a logger for functions that only log when the caller passes invalid input. Too much churn for negligible benefit.
- **Convert to services**: Rejected — kills ergonomics of pure functions, hurts testability.
- **Non-DI logger module**: Rejected — duplicates LoggerService's log-level logic, creates two implementations to maintain. Contradicts the goal of this task.
- **Keep console.error (chosen)**: These are essentially `assert` statements for caller bugs. They won't generate production noise, won't benefit from log-level filtering, and when Sentry lands (Task 09), the `GlobalErrorHandler` (Task 03) will catch any exceptions they lead to.

Add `// eslint-disable-next-line no-console -- Pure function, no DI access` to each line.

### logger.service.ts internal calls — keep with eslint-disable

Lines 55-58 use raw `console.warn`/`console.error` to report failures parsing its own settings from sessionStorage. This is correct — the logger can't call itself recursively. The switch/case block (lines 117-136) that wraps console methods is the legitimate output path.

Add `// eslint-disable-next-line no-console` to each internal console call.

### Commented-out dead code — delete, don't migrate

`tree-state.service.ts` has a `logTreeState()` method (lines 815-822) with everything commented out — 5 console.group/log calls that are dead code. Delete the entire method body rather than converting commented-out console calls to commented-out logger calls.

### Production log level — silence is acceptable

`LoggerService` defaults to `LogLevel.ERROR` in production (`isDevMode() ? DEBUG : ERROR`). After migration, all `logger.debug()`, `logger.info()`, and `logger.warn()` calls become no-ops in production. This is a behavioral change from today (where raw `console.debug` calls *do* appear in production consoles).

**Accepted trade-off**: Production gets quieter (less noise), and developers can still enable lower log levels via `LoggerService.setLogSettings()` which persists to sessionStorage. No action needed.

### ESLint — not installed, preemptive comments only

The project has no ESLint setup (no config, no dependency, no lint script). A separate task has been created at `.agents/tasks/20260403-eslint-setup/plan.md` for full ESLint adoption.

For this task: add `// eslint-disable-next-line no-console` comments to all kept console calls so they're pre-approved when ESLint eventually lands with `no-console: error`. Regression prevention relies on code review until then.

---

## Approach

### Step 1: Add `eslint-disable-next-line no-console` Comments Preemptively

Add `// eslint-disable-next-line no-console` to every legitimate `console.*` call that will remain after migration:

- `src/main.ts` — bootstrap catch (1 call)
- `src/app/core/utils/date.ts` — `validateAndConvertDate()` error reporting (5 calls)
- `src/app/core/utils/uri.ts` — `decodeStateParams()` error reporting (1 call)
- `src/app/core/services/logger/logger.service.ts` — self-diagnostic messages (lines 55-58: 2 calls) + switch/case output path (lines 117-136: 6 calls)

**Total: ~15 eslint-disable comments** across 4 files.

### Step 2: Delete Dead Code

- `src/app/trees-viewer/tree/tree-state.service.ts` — Delete the commented-out `logTreeState()` method body (lines 815-822).

### Step 3: Replace Direct console.* Calls

For each of the ~21 files (~52 calls to migrate):
1. Inject `LoggerService` (using `inject()`)
2. Replace `console.error(...)` → `this.logger.error(...)`
3. Replace `console.warn(...)` → `this.logger.warn(...)`
4. Replace `console.debug(...)` → `this.logger.debug(...)`
5. Replace `console.info(...)` → `this.logger.info(...)`
6. Replace `console.log(...)` → `this.logger.debug(...)` (log → debug mapping)

### Files to Migrate

**WebSocket/Connection layer (4 files, ~14 calls):**
- `src/app/core/services/websocket/websocket-health-state.service.ts` — 8 console.debug calls
- `src/app/shared/services/network/connection.service.ts` — 3 calls (debug logging of connection status)
- `src/app/notifications/sockets/abstract-socket-connection.ts`
- `src/app/notifications/sockets/web-socket-communication.ts`

**Tree viewer (5 files, ~20 calls — heaviest area):**
- `src/app/trees-viewer/tree/tree-state.service.ts` — 8 real calls to migrate + dead code to delete
- `src/app/trees-viewer/tree/services/tree-loading.service.ts` — 1 call
- `src/app/trees-viewer/tree/tree-item/tree-item-privileges/tree-item-privileges.component.ts` — 1 call
- `src/app/trees-viewer/nj-main/nj-process/nj-process-diagram-v/nj-diagram-interaction/nj-trace-settings/nj-trace-settings.component.ts` — 2 calls
- `src/app/trees-viewer/nj-main/header/query-time-picker/query-time-picker.component.ts` — 4 calls

**Shared services (5 files, ~6 calls):**
- `src/app/shared/services/user/user-session.service.ts` — 1 call
- `src/app/shared/services/autocomplete/elastic-query-autocomplete.service.ts` — 2 calls
- `src/app/shared/services/features/feature-status.service.ts` — 1 call
- `src/app/shared/services/features/module-compiler.service.ts` — 1 call
- `src/app/shared/directives/ace-editor/nj-ace-editor.ts` — 1 call

**Other (3 files, ~5 calls):**
- `src/app/administration/data-provider-admin/data-provider-admin-edit/data-provider-admin-edit.component.ts` — 1 call
- `src/app/argos/dashboard/editor/component-configuration/chart-configuration/chart-configuration.component.ts` — 2 calls
- `src/app/argos/dashboard/editor/component-configuration/rules/rules.component.ts` — 2 calls

**Core services (1 file, ~1 call):**
- `src/app/core/services/router/router-state.service.ts` — 1 call

### Files NOT Migrated (with eslint-disable comments instead)

- `src/main.ts` — LoggerService not available pre-bootstrap
- `src/app/core/utils/date.ts` — Pure function, no DI access
- `src/app/core/utils/uri.ts` — Pure function, no DI access
- `src/app/core/services/logger/logger.service.ts` — Can't call itself

### Files NOT Touched

- `src/app/core/utils/object.ts` — console calls only in JSDoc examples
- `src/app/core/utils/array.ts` — console call only in JSDoc example
- `cypress/e2e/admin/session/kill-session.cy.ts` — Test file
- All `.spec.ts` files — Test files

---

## Scope Summary

| Category | Files | Calls | Action |
|---|---|---|---|
| Migrate to LoggerService | 18 | ~52 | Replace with logger calls |
| Keep with eslint-disable | 4 | ~15 | Add eslint-disable comments |
| Delete dead code | 1 | 5 (commented out) | Delete `logTreeState()` body |
| No action (JSDoc/tests) | 3 | ~3 | Leave as-is |
| **Total** | **23** (unique) | **~65** | |

---

## Execution

Process by layer to minimize risk:
1. **Eslint-disable comments + dead code cleanup** — Quick pass, zero risk
2. **Core services** (`src/app/core/`) — Highest impact, fewest files (2 files)
3. **Shared services** (`src/app/shared/`) — Used everywhere (5 files)
4. **WebSocket/Connection layer** (`src/app/notifications/`, `src/app/core/services/websocket/`) — Critical path (4 files)
5. **Tree viewer** (`src/app/trees-viewer/`) — Heaviest area (5 files)
6. **Remaining feature modules** — Lower risk (3 files)

Each batch: migrate files → `ng build` → verify no regressions.

---

## Verification

1. `ng build` — Compiles after each batch
2. Grep for remaining `console.` calls in `src/` (excluding `.spec.ts`, `node_modules`) — only pre-approved exceptions remain, each with `// eslint-disable-next-line no-console`
3. Runtime behavior unchanged — Log output still appears in console via LoggerService (in dev mode). In production, only ERROR/FATAL level logs appear (accepted behavioral change).
4. `npm run test:prod` — Tests pass

---

## Why This Is Phase 1

This is foundational. Every subsequent refactoring (ErrorHandler, external monitoring, operator standardization) benefits from having a single logging path. Without this, adding Sentry later means wiring up 21 files instead of one.
