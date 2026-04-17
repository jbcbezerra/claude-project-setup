# Error Handling — Conventions & Rules

Rules for logging and RxJS error handling across the codebase.

---

## Logging

All Angular classes (services, components, directives, pipes) must use `LoggerService` instead of direct `console.*` calls.

### Injection

```typescript
import { LoggerService } from '@app/core/services/logger/logger.service';

private logger = inject(LoggerService);
```

### Level Mapping

| What to log | Method |
|---|---|
| Debug/trace info, `console.log` replacement | `this.logger.debug(...)` |
| Informational messages | `this.logger.info(...)` |
| Warnings | `this.logger.warn(...)` |
| Errors | `this.logger.error(...)` |

### Exceptions (keep `console.*` with eslint-disable)

These cases cannot use `LoggerService` and must keep raw `console.*` with `// eslint-disable-next-line no-console` on the line above:

- **`src/main.ts`** — LoggerService not available pre-bootstrap
- **Pure utility functions** outside Angular DI (`src/app/core/utils/`) — no injection context
- **`logger.service.ts` itself** — cannot call itself recursively
- **Plain classes** instantiated via `new` outside DI (e.g., `nj-ace-editor.ts`) — no injection context

### Forbidden

- `console.log()`, `console.debug()`, `console.info()`, `console.warn()`, `console.error()` in any Angular-managed class without `// eslint-disable-next-line no-console`

---

## RxJS Error Handling

### Reusable Operators (`src/app/core/utils/operator-functions.ts`)

Use the standardized operators instead of inline `catchError` blocks:

| Operator | Use when |
|---|---|
| `handleApiError(errorSubject)` | Stream should complete after pushing error to a Subject (state services) |
| `handleApiErrorWithDefault(defaultValue)` | Stream should emit a fallback value on error (component data loading) |

### When inline `catchError` is acceptable

- **Bespoke side effects** before returning EMPTY (e.g., state mutation, navigation, custom error handler calls) — these don't fit a generic operator
- **HTTP interceptor** — specialized status-code routing logic
- **WebSocket retry/reconnection** — exponential backoff is specialized
- **Re-throwing** (`catchError` + `throwError`) — intentional error propagation

### No logging inside operators

The HTTP interceptor already logs and surfaces errors before they reach `catchError` in individual services. Operators handle **stream recovery only** — they do not log.

### Forbidden

- `catchError(() => EMPTY)` without any side effect — use `handleApiErrorSilently()` (when added) or document why the error is intentionally discarded
- `catchError(() => of(defaultValue))` inline — use `handleApiErrorWithDefault(defaultValue)`
- `catchError(err => { subject.next(err); return EMPTY })` inline — use `handleApiError(subject)`

---

## JSON.parse

### Use `safeJsonParse` for untrusted string parsing

When parsing strings from localStorage, API responses, user config, or any external source, use the utility instead of bare `JSON.parse`:

```typescript
import { safeJsonParse } from '@app/core/utils/json';

// With typed fallback
const items = safeJsonParse<Item[]>(storedValue, []);

// With undefined fallback (overload returns T | undefined)
const config = safeJsonParse<Config>(rawString, undefined);
```

`safeJsonParse` requires a fallback — this forces callers to handle failure.

### When NOT to use `safeJsonParse`

- **Deep-clone idiom** (`JSON.parse(JSON.stringify(obj))`) — not error-prone, leave bare
- **Already inside a try-catch with proper handling** (logging, notification, recovery) — leave as-is
- **User-facing parse failures** (uploaded files, user-provided input) — use explicit try-catch with error notification so the user knows something went wrong

### Forbidden

- Bare `JSON.parse` on external/untrusted strings without try-catch or `safeJsonParse`
- Empty catch blocks around `JSON.parse` — at minimum use `safeJsonParse` with a fallback

---

## Silent Catch Blocks

### Forbidden

- `catch (_: unknown) {}` or `catch {}` — empty catches that swallow errors silently

### Minimum requirement

Every catch block must do at least one of:
- `logger.debug(...)` — for truly ignorable failures (DOM cleanup, optional operations)
- `logger.warn(...)` or `logger.error(...)` — for failures that indicate data issues
- User notification — for failures the user can act on
- Re-throw — for intentional error propagation
