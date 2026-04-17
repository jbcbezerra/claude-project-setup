# Standardize RxJS Error Handling Operators

## Context

The codebase has a reusable `handleApiError<T>()` operator in `src/app/core/utils/operator-functions.ts` that pipes errors to a Subject and returns EMPTY. However, several files implement their own inline `catchError` logic with varying patterns — fallback defaults, silent termination, manual error propagation — instead of using standardized operators.

**Note:** The original audit estimated 27+ files. Verified scope is ~7 files with ~8 catchError instances that map cleanly to standardized operators. The rest are bespoke side-effect patterns that don't fit a generic operator.

---

## Decisions (from interview 2026-04-03)

### Drop `handleApiErrorSilently` — no current use case

Every `catchError(() => EMPTY)` in the codebase does side effects before returning EMPTY (state mutation, navigation, error propagation). None are truly silent. The operator can be added trivially when a real use case emerges after future refactors.

### No logging inside operators

The HTTP interceptor (`globalHttpErrorHandlerInterceptor`) already logs and surfaces all HTTP errors before they reach individual `catchError` handlers. Operators handle **stream recovery only** — they don't need LoggerService. This avoids the injection-context problem (operator factory functions can't call `inject()` at subscription time).

### `config-state.ts` migrates to existing `handleApiError`

Both inline `catchError` blocks in `config-state.ts` are identical to `handleApiError(this.error$)`. Clean swap, no behavioral change.

### Bespoke side-effect patterns left alone

These files have custom logic before returning EMPTY that doesn't fit any generic operator:
- `sso.component.ts` — calls custom error handler, navigates away
- `openid-connect.component.ts` — sets `this.active = false`
- `admin-dashboard.service.ts` — inline error propagation (own pattern)

### Excluded from scope

- HTTP interceptor — specialized status-code routing
- WebSocket retry logic — exponential backoff is specialized
- `sessions-state.ts` — already uses `handleApiError` correctly

---

## Approach

### Step 1: Add `handleApiErrorWithDefault` operator

Extend `src/app/core/utils/operator-functions.ts`:

```typescript
export function handleApiErrorWithDefault<T>(defaultValue: T): OperatorFunction<T, T> {
  return catchError(() => of(defaultValue));
}
```

No logging, no side effects — pure stream recovery.

### Step 2: Migrate inline `catchError` patterns

| File | Current pattern | Migrates to |
|---|---|---|
| `src/app/shared/domain/config/config-state.ts` (2x) | `catchError(err => { this.error$.next(err); return EMPTY })` | `handleApiError(this.error$)` |
| `src/app/feature/shutdown/shutdown.component.ts` | `catchError(() => of(false))` | `handleApiErrorWithDefault(false)` |
| `src/app/trees-viewer/nj-main/nj-process-diagram-v/nj-process-diagram-v-api.service.ts` (2x) | `catchError(() => of([]))` | `handleApiErrorWithDefault([])` |
| `src/app/trees-viewer/nj-main/nj-process-details/nj-trace-table/activity-header/activity-header.component.ts` | `catchError(() => of({ name: '', type: '' } as Activity))` | `handleApiErrorWithDefault({ name: '', type: '' } as Activity)` |
| `src/app/trees-viewer/nj-custom-report/nj-custom-report-tile-wizard/tile.resolve.ts` | `catchError(() => of(njCustomReportTileFactory.get({}, {} as ExtendedTile)))` | `handleApiErrorWithDefault(njCustomReportTileFactory.get({}, {} as ExtendedTile))` |

---

## Scope Summary

| Category | Files | Instances | Action |
|---|---|---|---|
| Migrate to `handleApiError` | 1 | 2 | Swap inline pattern for existing operator |
| Migrate to `handleApiErrorWithDefault` | 4 | 5 | Swap inline pattern for new operator |
| Left alone (bespoke) | 3 | 4 | Inline `catchError` with custom side effects |
| Already correct | 2 | 4 | `feature-status.service.ts`, `sessions-state.ts` |
| Excluded | 2 | 2 | Interceptor, WebSocket manager |
| **Total** | **5** | **7** | |

---

## Execution

1. Add `handleApiErrorWithDefault` to `operator-functions.ts`
2. Migrate all 5 files in a single pass
3. `ng build` — verify compilation
4. Grep for orphaned inline `catchError(() => of(` patterns — count should be zero

---

## Verification

1. `ng build` — compiles
2. Grep for `catchError.*=>.*of(` excluding operator-functions.ts — zero hits expected
3. Runtime behavior unchanged — same fallback values, same stream completion, same error propagation
