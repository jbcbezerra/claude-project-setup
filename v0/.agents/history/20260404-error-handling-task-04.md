# Session: Error Handling Task 04

**Date:** 2026-04-04
**Goal:** Execute error handling task 04: eliminate silent catch blocks, create safeJsonParse utility, and wrap bare JSON.parse calls.

---

## Claude Session Brain

### Session transcript
- `/home/joao/.claude/projects/-home-joao-Desktop-server-njams-frontend/4fa0d72a-822a-40c9-a7d7-192f5460d737.jsonl`

### Session working directory
- `/home/joao/.claude/projects/-home-joao-Desktop-server-njams-frontend/4fa0d72a-822a-40c9-a7d7-192f5460d737/`

---

## Summary

### Interview (grill-me)
Interviewed task 04 plan. Revised scope significantly from original estimates (34 silent catches → 9, 25 JSON.parse → ~10 bare call sites). Classified each catch block and JSON.parse by risk. Decided safeJsonParse signature, fallback values, and which files need explicit try-catch vs utility.

### Execution
Used 3 subagents:
1. **Agent 1** — Created `safeJsonParse` utility in `src/app/core/utils/json.ts` with overloads and 8 unit tests
2. **Agent 2** (parallel) — Added `logger.debug()` to all 9 silent catches, injected LoggerService
3. **Agent 3** (parallel) — Wrapped ~10 bare `JSON.parse` calls in `safeJsonParse`, extracted `parsedTarget` getter in cell-details, added explicit try-catch to rule-file-uploader

### Build fixes
- Added `any` type annotation for chartConfig in tile-component (TS2339)
- Added `as unknown as string` cast in default-chart-config (TS2352)

### Post-execution cleanup
- Reverted 137 files that were touched by `npm run prettier` (full-project format) — only 18 task files kept
- Updated AGENT.md verification loop to forbid `npm run prettier` and require `npx prettier --write <changed-files>`
- Extended `.agents/rules/error-handling.md` with JSON.parse and silent catch block rules

---

## Key Decisions

- `safeJsonParse` only for bare parses — existing try-catches with proper handling left as-is
- `JSON.parse(JSON.stringify(...))` (deep-clone idiom) left alone — not error-prone
- `rule-file-uploader.ts` gets explicit try-catch with user notification, not safeJsonParse
- `safeJsonParse` fallback is required — forces callers to think about failure
- Overload for `undefined` return: `safeJsonParse<T>(value, undefined): T | undefined`
- Silent `new Function()` catches (custom tiles) → `logger.debug()` sufficient
- `cell-details.component.ts` → extracted duplicated `JSON.parse(this.target)` into `parsedTarget` getter
- AGENT.md: prettier must target only changed files, never `npm run prettier`
