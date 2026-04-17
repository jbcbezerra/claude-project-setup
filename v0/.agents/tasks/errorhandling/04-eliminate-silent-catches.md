# Eliminate Silent Catch Blocks + `safeJsonParse` Utility

## Context

22% of the 155+ try-catch blocks in the codebase swallow errors silently — empty catch blocks or catches that do nothing with the error. These accumulated over years as "defensive" coding but create invisible failure modes: when something breaks in production, there's no signal.

---

## Decisions (from interview 2026-04-04)

### Single task — silent catches + `safeJsonParse` done together

Both concerns are part of the same goal (eliminate invisible failures) and the scope is manageable in one pass.

### `JSON.parse(JSON.stringify(...))` left alone

Deep-clone idiom is not error-prone parsing. `safeJsonParse` only targets actual parsing of string inputs (localStorage reads, API responses, config strings).

### `safeJsonParse` only for bare parses

Existing try-catches with proper error handling (e.g., `user-properties.service.ts` which logs warnings) stay as-is. Only bare `JSON.parse` calls with no surrounding try-catch get wrapped.

### Bare parses where user needs feedback → explicit try-catch, not `safeJsonParse`

`rule-file-uploader.ts` parses user-uploaded files — failure means the user uploaded a bad file and needs error feedback. Use explicit try-catch with notification, not `safeJsonParse`.

### `safeJsonParse` signature

- `fallback` parameter is **required** — forces callers to think about failure
- Overload for `undefined` return: `safeJsonParse<T>(value, undefined): T | undefined`

### Silent `new Function()` catches → `logger.debug()` sufficient

Custom tile code execution errors (2 files) don't need user-facing feedback. Debug logging is enough.

### `cell-details.component.ts` → extract duplicated parse

`JSON.parse(this.target)` appears 3 times (lines 111, 128, 154). Extract into a getter instead of 3 separate `safeJsonParse` calls.

---

## Approach

### Step 1: Create `safeJsonParse` utility with unit tests

Create in `src/app/core/utils/json.ts`:

```typescript
export function safeJsonParse<T>(value: string | null | undefined, fallback: T): T;
export function safeJsonParse<T>(value: string | null | undefined, fallback: undefined): T | undefined;
export function safeJsonParse<T>(value: string | null | undefined, fallback: T | undefined): T | undefined {
  if (value == null) return fallback;
  try {
    return JSON.parse(value) as T;
  } catch {
    return fallback;
  }
}
```

### Step 2: Add `logger.debug()` to all 9 silent catches

All 9 are in Angular-managed classes (`@Injectable` or `@Component`) — `LoggerService` can be injected.

| # | File | What's caught | Action |
|---|------|---------------|--------|
| 1 | `navigation-list-sort-watcher.ts:61` | jQuery `.sortable('destroy')` | `logger.debug()` |
| 2 | `category-sort-watcher.ts:53` | jQuery `.sortable('destroy')` | `logger.debug()` |
| 3 | `nj-highcharts.module.ts:64` | `new Highcharts.Chart(...)` | `logger.debug()` |
| 4 | `sso-login-helper.service.ts:35` | `new URL(...)` parsing | `logger.debug()` |
| 5 | `user-layout-settings.service.ts:49` | Permission check on `stateDefinition.data.permissions` | `logger.debug()` |
| 6 | `time-range-calculator.service.ts:45` | `JSON.parse(timePickerEntry)` | `logger.debug()` |
| 7 | `cluster-nodes-status.component.ts:155` | `JSON.parse(storedListSort)` + sort restore | `logger.debug()` |
| 8 | `nj-custom-report-tile-wizard.component.ts:103` | `new Function(...)` user tile code | `logger.debug()` |
| 9 | `nj-custom-report-tile.component.ts:108` | `new Function(...)` user tile code | `logger.debug()` |

### Step 3: Wrap bare `JSON.parse` calls in `safeJsonParse`

| # | File | Line | Fallback |
|---|------|------|----------|
| 1 | `alerts-list.component.ts` | 181 | `[]` |
| 2 | `default-chart-config.ts` | 221 | skip parse (keep raw value) |
| 3 | `error-list.component.ts` | 690 | `{}` |
| 4 | `nj-custom-report-tile-wizard.component.ts` | 160 | `{}` |
| 5 | `nj-custom-report-tile-wizard.component.ts` | 164 | `[]` |
| 6 | `nj-custom-report-tile.component.ts` | 122 | `''` |
| 7 | `nj-custom-report-tile.component.ts` | 127 | `{}` |
| 8 | `nj-input-mapping.component.ts` | 116 | `null` (skip `parseInput` call) |
| 9 | `cell-details.component.ts` | 111, 128, 154 | `undefined` (extract to getter) |

### Step 4: Add explicit try-catch for user-facing parse failures

| # | File | Line | Action |
|---|------|------|--------|
| 1 | `rule-file-uploader.ts` | 59 | try-catch with error notification to user |

---

## Scope Summary

| Category | Count | Action |
|---|---|---|
| Silent catches | 9 | Add `logger.debug()` |
| Bare `JSON.parse` → `safeJsonParse` | ~10 call sites | Wrap with fallback |
| Bare `JSON.parse` → explicit try-catch | 1 (`rule-file-uploader.ts`) | try-catch with user notification |
| Extract duplicated parse | 1 (`cell-details.component.ts`) | Getter for parsed target |
| New utility | 1 (`json.ts` + `json.spec.ts`) | `safeJsonParse` with overloads |
| **Existing try-catches with proper handling** | **~15** | **Left as-is** |

---

## Execution

1. Create `safeJsonParse()` utility with unit tests
2. Process silent catches — add `logger.debug()` to all 9
3. Process bare `JSON.parse` calls — wrap in `safeJsonParse` or explicit try-catch
4. Extract `cell-details.component.ts` parsed target into getter
5. Add explicit try-catch to `rule-file-uploader.ts`

---

## Verification

1. `npx prettier --write` on all changed files
2. `npm run test:prod` — all tests pass
3. `npm run build:prod` — zero errors
4. Grep for `catch (_: unknown) {}` → zero results (excluding test files)
5. Grep for bare `JSON.parse` outside try-catch → reduced to only deep-clone patterns
6. No behavioral changes — fallback values and graceful degradation work identically

---

## Dependencies

- Task 01 (Centralized Logging) — done ✅ — LoggerService available for added log calls
