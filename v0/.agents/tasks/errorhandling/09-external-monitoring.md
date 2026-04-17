# Add External Error Monitoring Integration

## Context

The application has **zero external error monitoring**. No Sentry, LogRocket, Bugsnag, Datadog, or any other production error tracking service. All errors go to the browser console via `LoggerService` and are invisible unless a user reports them or a developer has devtools open.

This means:
- Production errors are undetectable until users complain
- No error frequency/trend data
- No environment/browser/user context attached to errors
- No alerting on error spikes
- No stack trace aggregation or deduplication

This task is intentionally last because it depends on the infrastructure from prior tasks:
- Task 01 (Centralized Logging) — All logging through `LoggerService`
- Task 03 (Global ErrorHandler) — Catches all uncaught exceptions
- Task 08 (Interceptor Refactor) — Clean strategy-based HTTP error handling

With those in place, adding external monitoring becomes a minimal-surface-area change.

---

## Approach

### Step 1: Choose a Monitoring Service

Evaluate based on project needs (self-hosted vs. SaaS, budget, features):

| Service | Self-hosted | Free Tier | Key Feature |
|---|---|---|---|
| **Sentry** | Yes (open-source) | 5K errors/month | Best Angular integration, source maps |
| **Datadog RUM** | No | Limited | Full observability suite |
| **LogRocket** | No | 1K sessions/month | Session replay |
| **Bugsnag** | No | 7.5K events/month | Stability scoring |

Recommendation: **Sentry** — open-source option available, best Angular SDK, source map support, mature error grouping.

### Step 2: Create a Monitoring Service Abstraction

Create `src/app/core/services/monitoring/error-monitoring.service.ts`:

```typescript
@Injectable({ providedIn: 'root' })
export class ErrorMonitoringService {
  /**
   * Report an error to external monitoring.
   * Abstracts the specific provider so it can be swapped.
   */
  captureError(error: unknown, context?: Record<string, unknown>): void { ... }

  /**
   * Set user context for error reports.
   */
  setUser(user: { id: string; username: string } | null): void { ... }

  /**
   * Add breadcrumb for debugging context.
   */
  addBreadcrumb(message: string, category: string): void { ... }
}
```

This abstraction means the rest of the codebase never imports Sentry directly — swapping providers is a one-file change.

### Step 3: Integrate with Existing Infrastructure

**Three integration points (all already centralized from prior tasks):**

1. **`GlobalErrorHandler`** (from Task 03) — Call `errorMonitoring.captureError()` for all uncaught errors
2. **`LoggerService`** (from Task 01) — Optionally call `errorMonitoring.addBreadcrumb()` on warn/error log calls for context trail
3. **HTTP Interceptor** (from Task 08) — Call `errorMonitoring.captureError()` for HTTP errors that aren't user-dismissible

### Step 4: Configure Source Maps

Upload source maps during CI/CD build so stack traces in the monitoring dashboard map to original TypeScript code:

```bash
# Example for Sentry (add to CI/CD pipeline)
npx @sentry/cli sourcemaps upload --release=$VERSION dist/
```

### Step 5: Add User Context

After login, set user context so errors are attributed:

```typescript
// In UserSessionService or login flow
this.errorMonitoring.setUser({ id: user.id, username: user.username });

// On logout
this.errorMonitoring.setUser(null);
```

### Files to Create

- `src/app/core/services/monitoring/error-monitoring.service.ts` — Provider-agnostic monitoring service
- `src/app/core/services/monitoring/error-monitoring.service.spec.ts` — Unit tests
- `src/app/core/services/monitoring/sentry.config.ts` — Sentry-specific initialization (DSN, environment, release, sample rate)

### Files to Modify

- `src/main.ts` — Initialize monitoring before Angular bootstrap
- `src/app/core/error-handling/global-error-handler.ts` (from Task 03) — Add `errorMonitoring.captureError()`
- `src/app/core/services/logger/logger.service.ts` — Optionally add breadcrumbs on error/warn
- `src/app/shared/services/user/user-session.service.ts` — Set/clear user context on login/logout
- `angular.json` or build config — Source map upload step
- `package.json` — Add monitoring SDK dependency

---

## Execution

1. Install monitoring SDK (e.g., `@sentry/angular`)
2. Create `ErrorMonitoringService` with provider abstraction
3. Initialize in `main.ts` before bootstrap
4. Integrate with `GlobalErrorHandler`
5. Integrate with `LoggerService` (breadcrumbs)
6. Add user context in login/logout flow
7. Configure source map upload in CI/CD
8. Set up alerting rules in monitoring dashboard (error spike thresholds)

---

## Verification

1. `ng build` — Compiles
2. Trigger a deliberate error → Verify it appears in monitoring dashboard with:
   - Correct stack trace (mapped to TypeScript via source maps)
   - User context attached
   - Breadcrumb trail from recent log calls
3. Trigger an HTTP error → Verify it appears in monitoring (not just as a toast)
4. Verify no PII leakage — Only user ID and username, no passwords or tokens
5. `npm run test:prod` — Tests pass
6. Performance: Monitoring SDK bundle size is acceptable (Sentry Angular ~30KB gzipped)
7. Sampling rate is tuned to avoid quota exhaustion

---

## Dependencies

- **Task 01** (Centralized Logging) — All log calls go through LoggerService
- **Task 03** (Global ErrorHandler) — Catches all uncaught exceptions
- **Task 08** (Interceptor Refactor) — Clean integration point for HTTP errors

Without these, monitoring would need to be wired into 87+ files instead of 3.

---

## Privacy & Security Considerations

- Never send passwords, tokens, or session IDs to monitoring
- Configure PII scrubbing in monitoring dashboard settings
- Review data retention policies with your compliance requirements
- Consider self-hosted Sentry if data must stay on-premises
