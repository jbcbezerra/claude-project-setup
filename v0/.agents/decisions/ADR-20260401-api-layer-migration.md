# ADR-20260401: Migrate from Custom XHR API Layer to Angular HttpClient

## Status

Complete (2026-04-03) — All 56 endpoints migrated, legacy `src/app/api/manual/` infrastructure removed.

## Context

The frontend has two coexisting API layers:

- **Old:** `src/app/api/manual/` — A custom HTTP client built on raw `XMLHttpRequest`, predating Angular's `HttpClient`. Returns `Promise<T>`.
- **New:** `src/app/core/services/api/` — Built on Angular's `HttpClient`. Returns `Observable<T>`.

The old layer was necessary when the project started because Angular's `HttpClient` did not exist yet. It has since become a source of technical debt. Below are the specific problems that justify this migration.

---

## Problem 1: Duplicated Request Building Code

The old `BaseApi` (`src/app/api/manual/base-api.ts`) contains 12 protected HTTP methods that all follow the same pattern: instantiate a `RequestBuilder`, chain 2-4 configuration calls, call `.build()` to produce a `RequestOptions` object, then pass it to `httpRequest.process()`.

```typescript
// This pattern is repeated 12 times with minor variations
protected getJson<T>(path: string) {
    const requestBuilder = new RequestBuilder();
    const request = requestBuilder.get().acceptJson().build();
    return this.httpRequest.process<T>(`${this.apiEndpoint}${path}`, request);
}
```

Several methods are near-duplicates with only trivial differences:

| Method A | Method B | Difference |
|----------|----------|------------|
| `post()` | `postAndGetJson()` | Identical implementation |
| `post()` | `postWithoutResponse()` | Identical implementation |
| `put()` | `putAndGetJson()` | Identical implementation |
| `delete()` | `deleteWithoutResponse()` | Only content-type header |
| `getJson()` | `getJsonWithAuthorizationHeader()` | Only auth header |

The `RequestBuilder` (`src/app/api/manual/request-builder.ts`) and `RequestOptions` (`src/app/api/manual/request-options.ts`) exist solely to construct what Angular's `HttpClient` accepts natively. They are 100+ lines of indirection that produce a simple `{ method, body, headers }` object.

**New layer:** A single `this.http.get<T>(url, options)` call replaces the entire builder chain. The base service is ~30 lines of meaningful code vs ~100 lines of boilerplate.

---

## Problem 2: Fragmented Error Handling

The old layer has **three separate error representations** that are used inconsistently:

### ResponseError (`src/app/api/manual/ResponseError.ts`)

Marked as `@deprecated`. Extracts 7 properties from the raw `XMLHttpRequest` object. Loses HTTP response headers, the full response body, and Angular-standard error context. Manually parses `xhr.response` as JSON (line 23) which can silently fail.

### ResponseParsingError (`src/app/api/manual/ResponseParsingError.ts`)

A minimal wrapper used when JSON parsing fails. Converts the entire response to a JSON string with no structured information.

### Raw string throws

In `xml-http-request.ts`, the `parseResponseToText()` and `parseResponseToBlob()` methods throw `response.statusText` directly — a plain string, not an Error object. Consumers cannot distinguish this from other error types.

### Consumer inconsistency

Different consumers handle errors differently, or not at all:

- Some use `.catch()` with error details: `nj-extract-expression.component.ts`
- Some use `.catch()` but swallow all errors silently: `add-category.service.ts` — `catch(() => { return [] as Category[]; })`
- Some have no error handling at all: `layout-settings.component.ts`, `saveCategory()` in `add-category.service.ts`

**New layer:** Angular's `HttpErrorResponse` provides a single, consistent error type with `status`, `statusText`, `url`, `headers`, `error` (parsed body), and `message`. All errors flow through Angular's interceptor chain. Consumer error handling uses `.subscribe({ error })` which is structurally enforced.

---

## Problem 3: Manual XHR Implementation

`XmlHttpRequest` (`src/app/api/manual/xml-http-request.ts`) is a 141-line hand-rolled HTTP client that manually wraps `XMLHttpRequest` in Promises. It reimplements what Angular's `HttpClient` provides out of the box:

### Manual response type detection (lines 84-96)

```typescript
if (request.headers && request.headers['Accept'] === 'application/octet-stream') {
    return this.parseResponseToBlob(response);
} else if (request.headers && request.headers['Accept'] === 'text/plain') {
    return this.parseResponseToText(response);
} else {
    return this.parseResponseToJson(response);
}
```

Response type is inferred by checking the `Accept` header string — fragile and error-prone. Angular's `HttpClient` handles this via the `responseType` option with compile-time type safety.

### Silent parse failures (line 108)

```typescript
parseResponseToJson(response: any) {
    try {
        return JSON.parse(response.response);
    } catch (_: unknown) {}  // silently returns undefined
}
```

If JSON parsing fails, the method returns `undefined` silently. Consumers receive `undefined` as a success value instead of an error.

### Custom interceptor chain (lines 66-68)

```typescript
for (let interceptor of this.interceptors) {
    response = interceptor.intercept(path, response);
}
```

A custom `HttpInterceptor` interface (`src/app/api/manual/http-interceptor.ts`) that works on Promises instead of Angular's `HttpRequest`/`HttpHandler`. Only one implementation exists (`ResponseErrorHandler`), which is itself marked `@deprecated`. This duplicates Angular's built-in interceptor mechanism.

### String-based DI token

The XHR implementation is provided via a string token `'HttpRequest'` in `app.module.ts`, forcing every endpoint class to use `@Inject('HttpRequest')` instead of type-safe injection.

---

## Problem 4: Module Registration Overhead & No Tree-Shaking

`api.module.ts` (`src/app/api/manual/api.module.ts`) manually lists 42 API endpoint classes in a `providers` array. Every new endpoint requires:

1. Create the class extending `BaseApi`
2. Import it in `api.module.ts`
3. Add it to the `providers` array

All 42 classes are bundled in the application regardless of whether they are used on a given page. There is no tree-shaking.

**New layer:** Services use `@Injectable({ providedIn: 'root' })`. No module registration needed. Angular tree-shakes unused services automatically.

---

## Problem 5: Promise/Observable Impedance Mismatch

The old API returns Promises while the rest of the Angular application uses Observables. This creates friction:

- **Conversion anti-patterns:** Some services convert Observables back to Promises with `.toPromise()` (e.g., `nj-activity-stats.service.ts` line 18) then chain with `.then()`, defeating the purpose of RxJS.
- **No cancellation:** Promises cannot be cancelled. When a user navigates away, in-flight HTTP requests continue and their callbacks execute on destroyed components, causing errors or memory leaks.
- **No composition:** Promise chains (`.then().then().then()`) are less composable than RxJS pipes (`pipe(map(), switchMap(), catchError())`). Complex async flows like parallel requests, retry logic, debouncing, or cancellation require manual workarounds with Promises but are built-in with RxJS operators.
- **No takeUntilDestroyed:** Angular's `takeUntilDestroyed` operator provides automatic subscription cleanup tied to component lifecycle. This has no Promise equivalent.

---

## Decision

Migrate all API endpoints from the old `src/app/api/manual/` layer to new services in `src/app/core/services/api/`, using Angular's `HttpClient` and returning `Observable<T>`.

The migration is incremental — one endpoint at a time — to minimize risk. Each migration includes updating all consumers from Promise patterns to Observable patterns.

Once all endpoints are migrated, the entire `src/app/api/manual/` directory, including `BaseApi`, `RequestBuilder`, `XmlHttpRequest`, `ResponseError`, `ResponseParsingError`, the custom `HttpInterceptor` interface, and `ApiModule`, will be removed.

## Consequences

- **Positive:** Single HTTP layer, consistent error handling, tree-shaking, automatic subscription cleanup, RxJS composition, Angular interceptor support, reduced bundle size, no more string-based DI tokens
- **Negative:** Migration effort across 40+ endpoints and their consumers; risk of subtle behavioral changes during Promise→Observable conversion (timing, error propagation)
- **Mitigated by:** Incremental migration, build validation after each endpoint, documented workflow (`.agents/workflows/api-migration-workflow.md`), enforced conventions (`.agents/rules/api-services.md`)
