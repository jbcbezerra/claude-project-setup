# Add Global Angular ErrorHandler

## Context

The application has **no Angular `ErrorHandler` override**. Uncaught exceptions in components, template expressions, lifecycle hooks, and async operations hit the browser console and disappear. The only structured error handling is the HTTP interceptor (catches HTTP errors) and individual try-catch blocks (catches known failure points). Everything else — unhandled promise rejections, template binding errors, ngOnInit crashes — is invisible in production.

---

## Decisions (from interview 2026-04-03)

### Always log, skip notification only for HTTP errors

The HTTP interceptor (`globalHttpErrorHandlerInterceptor`) re-throws errors via `throwError()` after handling them. When a subscriber doesn't catch the re-thrown error, it bubbles up to the ErrorHandler. The ErrorHandler must:

- **Always** call `this.logger.error()` — including for HttpErrorResponse. This ensures errors the interceptor intentionally suppresses (codes `00017`, `00190`, `00057`, `00102` and filtered URL patterns) still get a log entry.
- **Skip user notification** only when the error is `instanceof HttpErrorResponse` — the interceptor already showed a toast for those.

### Toast, not modal

Use `stageError()` (persistent toast, bottom-right) instead of `showErrorMessage()` (blocking modal dialog).

- Consistent with the interceptor's notification style
- Non-blocking — runtime errors often happen in background operations the user can't act on
- Toastr's native `preventDuplicates` handles repeated errors (e.g., template binding firing in a loop)

### No custom deduplication

The plan originally proposed a 2s deduplication window. Dropped — toastr config already has `preventDuplicates: true` and max 4 toasts open.

### Generic user message

Toast always shows `'An unexpected error occurred.'` — no error details exposed to end users. Full error details go to `logger.error()` only. Developers check console (dev mode) or future monitoring (Task 09) for details.

### Self-protection

The `handleError` body is wrapped in try-catch with a raw `console.error` fallback. The ErrorHandler cannot call itself recursively. Add `// eslint-disable-next-line no-console` per the error-handling rule.

### No spec file

An ErrorHandler that delegates to logger + notifications isn't meaningfully unit-testable. Integration/manual testing is more appropriate: trigger a runtime error, verify toast appears and logger captures it.

---

## Approach

### Step 1: Create GlobalErrorHandler

Create `src/app/core/error-handling/global-error-handler.ts`:

```typescript
import { ErrorHandler, inject, Injectable, NgZone } from '@angular/core';
import { HttpErrorResponse } from '@angular/common/http';
import { LoggerService } from '../services/logger/logger.service';
import { NotificationsService } from '../../../notifications/notifications.service';

@Injectable()
export class GlobalErrorHandler implements ErrorHandler {
  private logger = inject(LoggerService);
  private notifications = inject(NotificationsService);
  private zone = inject(NgZone);

  handleError(error: unknown): void {
    try {
      const unwrapped = this.unwrapError(error);

      this.logger.error('Unhandled error:', unwrapped);

      if (!(unwrapped instanceof HttpErrorResponse)) {
        this.zone.run(() => {
          this.notifications.stageError('An unexpected error occurred.');
        });
      }
    } catch (fallbackError) {
      // eslint-disable-next-line no-console
      console.error('GlobalErrorHandler failed:', fallbackError);
      // eslint-disable-next-line no-console
      console.error('Original error:', error);
    }
  }

  private unwrapError(error: unknown): unknown {
    // Zone.js wraps unhandled promise rejections
    if (error && typeof error === 'object' && 'rejection' in error) {
      return (error as any).rejection;
    }
    return error;
  }
}
```

### Step 2: Register provider

In `src/app/app.module.ts`, add to providers:

```typescript
{ provide: ErrorHandler, useClass: GlobalErrorHandler }
```

---

## Files

| Action | File |
|---|---|
| Create | `src/app/core/error-handling/global-error-handler.ts` |
| Modify | `src/app/app.module.ts` — add ErrorHandler provider |

---

## Verification

1. `npx prettier --write <changed-files>`
2. `npm run test:prod` — all tests pass
3. `npm run build:prod` — compiles with zero errors
4. Manual runtime check: trigger a deliberate error → toast appears + logger captures it
5. Manual HTTP check: trigger an HTTP error → only ONE notification (from interceptor, not ErrorHandler)

---

## Dependencies

- Task 01 (Centralized Logging) — done. LoggerService is the established logging path.

## Future Integration

This becomes the single hook point for external monitoring (Task 09). When Sentry/Datadog is added, it integrates here — one file, not scattered across the codebase.
