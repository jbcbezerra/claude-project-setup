# Session: Error Handling Tasks 01-03

**Date:** 2026-04-03
**Goal:** Execute the first three error handling tasks: centralized logging migration, RxJS error operator standardization, and global Angular ErrorHandler.

---

## Claude Session Brain

### Session transcript
- `/home/joao/.claude/projects/-home-joao-Desktop-server-njams-frontend/8b8855ef-161e-438e-8ee0-abb0b5091793.jsonl`

### Session working directory
- `/home/joao/.claude/projects/-home-joao-Desktop-server-njams-frontend/8b8855ef-161e-438e-8ee0-abb0b5091793/`

---

## Summary

### Task 01 — Centralized Logging
Migrated ~26 console.* calls to LoggerService across 18 files using 4 parallel subagents. Added 16 eslint-disable comments for legitimate console calls (pure functions, logger internals, pre-bootstrap, non-DI classes). Deleted dead code in `logTreeState()`. One file (`nj-ace-editor.ts`) could not be migrated (plain class outside DI context) — eslint-disable added instead.

### Task 02 — RxJS Error Operators (interviewed + executed)
Original plan claimed 27+ files — verified scope was only ~7. Dropped `handleApiErrorSilently` (no current use case). Added `handleApiErrorWithDefault<T>()` operator to `operator-functions.ts`. Migrated 5 files (7 instances) from inline `catchError` to standardized operators. Fixed type inference issue with `handleApiErrorWithDefault<Activity[]>([])`.

### Task 03 — Global ErrorHandler (interviewed + executed)
Created `GlobalErrorHandler` in `src/app/core/error-handling/global-error-handler.ts`. Registered in `app.module.ts`. Key design decisions: always log (even HTTP errors), skip toast only for HttpErrorResponse, use `stageError()` toast (not modal), no custom deduplication (toastr handles it), generic user message.

### Cross-cutting
Created `.agents/rules/error-handling.md` — covers both logging conventions (LoggerService usage, level mapping, exceptions) and RxJS error handling (operator usage, when inline catchError is acceptable).

---

## Key Decisions

- Pure utility functions keep `console.*` with eslint-disable — no DI threading for negligible benefit
- `nj-ace-editor.ts` stays with `console.error` — plain class outside Angular DI, would require constructor refactor across 7+ call sites
- No logging inside RxJS error operators — HTTP interceptor already handles error visibility
- `handleApiErrorSilently` dropped — no current use case, add when needed
- GlobalErrorHandler always logs, skips notification only for HttpErrorResponse
- Toast (`stageError`) for runtime errors, not modal — consistent with interceptor, non-blocking
- Generic "An unexpected error occurred." message — full details in logger only
- No spec file for GlobalErrorHandler — integration testing more appropriate
