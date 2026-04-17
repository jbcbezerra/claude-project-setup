# Refactor HTTP Error Interceptor to Strategy Pattern

## Context

The global HTTP error interceptor at `src/app/core/interceptors/global-http-error-handler/global-http-error-handler.interceptor.ts` is the single most critical error handling file in the codebase. It handles all HTTP errors with a large if/else chain for status codes (0, -1, 401, 403, 404, 503, 504, default) and has hardcoded error code filters (00017, 00190, 00057, 00102).

The current implementation works but has grown organically:
- Each status code handler is an inline block with mixed concerns (logging, notification, routing, connection state)
- Error code filtering is a hardcoded array with no documentation of why those codes are filtered
- Lazy dependency injection (`inject()` calls inside the function body) to prevent cyclic dependencies
- The `TemporaryIgnoredRequestError` service adds another layer of conditional logic

This makes it hard to understand the full error handling flow at a glance, difficult to add new status code handlers, and risky to modify existing ones.

---

## Approach

### Step 1: Extract Status Code Handlers into a Strategy Map

Replace the if/else chain with a declarative map:

```typescript
type ErrorStrategy = (error: HttpErrorResponse, services: ErrorHandlerServices) => void;

const ERROR_STRATEGIES: Map<number, ErrorStrategy> = new Map([
  [0, handleNetworkError],
  [-1, handleNetworkError],
  [401, handleUnauthorized],
  [403, handleUnauthorized],
  [404, handleNotFound],
  [503, handleServiceUnavailable],
  [504, handleGatewayTimeout],
]);

// Default strategy for unmatched status codes
const DEFAULT_STRATEGY: ErrorStrategy = handleGenericError;
```

Each strategy is a pure function in its own file or grouped logically:

```
src/app/core/interceptors/global-http-error-handler/
  global-http-error-handler.interceptor.ts  — Main interceptor, delegates to strategies
  error-response.ts                          — ErrorResponse interface (existing)
  strategies/
    network-error.strategy.ts               — Status 0, -1
    unauthorized.strategy.ts                — Status 401, 403
    not-found.strategy.ts                   — Status 404
    service-unavailable.strategy.ts         — Status 503
    gateway-timeout.strategy.ts             — Status 504
    generic-error.strategy.ts               — Default fallback
  error-code-filters.ts                     — Documented filtered error codes
```

### Step 2: Document and Extract Error Code Filters

Move the hardcoded error code array to a named constant with documentation:

```typescript
/**
 * Error codes that should NOT trigger user-visible notifications.
 * These represent expected/non-critical conditions.
 */
export const SUPPRESSED_ERROR_CODES: ReadonlySet<string> = new Set([
  '00017', // [document why this is filtered]
  '00190', // [document why this is filtered]
  '00057', // [document why this is filtered]
  '00102', // [document why this is filtered]
]);
```

### Step 3: Create a Services Facade

Bundle the lazy-injected services into a typed object to simplify strategy signatures:

```typescript
interface ErrorHandlerServices {
  logger: LoggerService;
  notifications: NotificationsService;
  connection: ConnectionService;
  router: RouterStateService;
  userSession: UserSessionService;
  pendingRequests: PendingRequestsService;
  ignoredErrors: TemporaryIgnoredRequestError;
}
```

### Files to Create/Modify

**New files:**
- `src/app/core/interceptors/global-http-error-handler/strategies/network-error.strategy.ts`
- `src/app/core/interceptors/global-http-error-handler/strategies/unauthorized.strategy.ts`
- `src/app/core/interceptors/global-http-error-handler/strategies/not-found.strategy.ts`
- `src/app/core/interceptors/global-http-error-handler/strategies/service-unavailable.strategy.ts`
- `src/app/core/interceptors/global-http-error-handler/strategies/gateway-timeout.strategy.ts`
- `src/app/core/interceptors/global-http-error-handler/strategies/generic-error.strategy.ts`
- `src/app/core/interceptors/global-http-error-handler/error-code-filters.ts`

**Modified files:**
- `src/app/core/interceptors/global-http-error-handler/global-http-error-handler.interceptor.ts` — Simplify to strategy dispatch

---

## Execution

1. Create the strategies directory and extract each status code handler as-is (no behavior changes)
2. Create the error-code-filters.ts with documented constants
3. Refactor the interceptor to use the strategy map
4. Add/update unit tests for each strategy in isolation
5. `ng build` → full integration testing

---

## Verification

1. `ng build` — Compiles
2. **Status 0/network error** → Backend marked offline, network error overlay appears
3. **Status 401** → User logged out, redirected to login
4. **Status 403** → Same as 401
5. **Status 503 + NJAMS_DOWN** → Redirected to shutdown page
6. **Status 504** → Backend marked offline
7. **Status 404** → Appropriate handling based on cluster mode
8. **Other status codes** → Generic error notification shown
9. **Suppressed error codes** → No notification shown
10. **Temporarily ignored URLs** → No notification shown
11. `npm run test:prod` — Tests pass
12. Zero behavior changes — only structural refactoring

---

## Risk Assessment

This is a **high-risk refactoring** because the interceptor processes every HTTP error in the application. Mitigate by:
- Extracting strategies with zero logic changes (pure structural refactor)
- Testing each strategy in isolation
- Full regression testing of all error scenarios before merging
