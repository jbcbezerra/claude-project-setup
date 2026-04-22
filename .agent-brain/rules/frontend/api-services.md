# API Services — Conventions & Rules

Rules for creating and modifying domain API services in `src/app/core/services/api/<domain>/`.

> **Canonical skeletons:**
> - [patterns/frontend/base-service.md](../../patterns/frontend/base-service.md) — every API service extends `BaseService`.
> - [patterns/frontend/api-http-client.md](../../patterns/frontend/api-http-client.md) — the `Api` / `BaseApi` HTTP wrapper every service injects.
>
> These rules assume the project-level `Api` wrapper exists (it centralizes base URL, default headers, `take(1)`, endpoint normalization). If your project doesn't have one, introduce it using the pattern above — don't inject `HttpClient` directly from domain services.

---

## File & Class Naming

- File: `<domain>-api.ts` inside `src/app/core/services/api/<domain>/`.
- Class: `<Domain>Api` (e.g. `ServerApi`, `AuditApi`, `LogApi`).
- One service per domain — group all endpoints for a domain in a single `<domain>-api.ts`.

## Injectable Pattern

Always use tree-shakable `providedIn: 'root'`.

```typescript
@Injectable({
    providedIn: 'root',
})
export class ExampleApi extends BaseService {
```

## Base Class

Extend the project's `BaseService` (see [pattern](../../patterns/frontend/base-service.md), typically located under `shared/services/base-service.ts`). `BaseService` wires up the scoped `Logger` and emits a standard init log line.

```typescript
import { BaseService } from '<relative-path>/shared/services/base-service';

export class ExampleApi extends BaseService { ... }
```

## Dependency Injection

```typescript
private readonly api = inject(Api);
```

- Always inject the project's `Api` wrapper (from `core/http/api.ts` — see [api-http-client.md](../../patterns/frontend/api-http-client.md)). **Never** inject `HttpClient`, `BaseApi`, or use `fetch` directly. `Api` is the single entry point so request defaults (headers, base path, `take(1)`) stay consistent.
- Never subclass `BaseApi` from a domain service — only `core/http/*.ts` files do that. Domain services extend `BaseService` and inject `Api`.

## Endpoint Comments

Group methods by their REST endpoint path using section comments. This makes it easy to locate which methods correspond to which backend endpoint:

```typescript
// ========== /server ==========
createServer(payload: CreateServerPayload): Observable<ServerActionResponse> {
    return this.api.post<ServerActionResponse>('/server', payload);
}

editServer(payload: EditServerPayload): Observable<void> {
    return this.api.patch<void>('/server', payload);
}

// ========== /server/{id} ==========
deleteServer(id: string): Observable<ServerActionResponse> {
    return this.api.delete<ServerActionResponse>(`/server/${id}`);
}

// ========== /server/{id}/start ==========
startServer(id: string): Observable<ServerActionResponse> {
    return this.api.post<ServerActionResponse>(`/server/${id}/start`, {});
}
```

- Use the format `// ========== /endpoint/path ==========`.
- Place the comment above the first method that hits that endpoint.
- Methods sharing the same endpoint path (different HTTP verbs) go under the same comment.
- Include path parameters as `{name}` in the comment.

## Method Conventions

### Return Types

All methods return `Observable<T>`. Never return `Promise<T>`. Use `Observable<void>` for fire-and-forget mutations that return no body.

```typescript
getServers(): Observable<ServerDto[]> {
    return this.api.get<ServerDto[]>('/servers');
}
```

Explicit return type annotations are mandatory.

### Method Naming

Methods are named after **intent**, not the HTTP verb. Pick a prefix from the table:

| Operation         | Prefix                            | Example                                |
|-------------------|-----------------------------------|----------------------------------------|
| Fetch single      | `get*`                            | `getServer(id)`                        |
| Fetch list        | `getAll*`, `list*`, `get*s`       | `getServers()`, `listBranches()`       |
| Create            | `create*`                         | `createServer(payload)`                |
| Update            | `update*`, `edit*`, `change*`, `set*` | `editServer(payload)`, `setFlavor(x)` |
| Delete            | `delete*`, `remove*`              | `deleteServer(id)`                     |
| Action (verb-ish) | `start*`, `stop*`, `restart*`     | `startServer(id)`, `stopServer(id)`    |
| Check/test        | `check*`, `has*`, `is*`           | `hasPermission(body)`, `isReady()`     |
| Toggle            | `activate*`, `deactivate*`, `enable*`, `disable*` | `activateFeature()`    |

### Available HTTP Methods

Only the methods exposed by the project's `Api` / `BaseApi` are available (see [api-http-client.md](../../patterns/frontend/api-http-client.md)). If you need something not in this table, add it to `BaseApi` rather than reaching around it with raw `HttpClient`.

| Method     | Signature                                                | Notes                   |
|------------|----------------------------------------------------------|-------------------------|
| `get<T>`   | `this.api.get<T>(path, options?)`                        | Single item             |
| `getAll<T>`| `this.api.getAll<T>(path, options?)`                     | Array of items          |
| `post<T>`  | `this.api.post<T>(path, body?, options?)`                | Create / action         |
| `put<T>`   | `this.api.put<T>(path, body?, options?)`                 | Full replace            |
| `patch<T>` | `this.api.patch<T>(path, body?, options?)`               | Partial update          |
| `delete<T>`| `this.api.delete<T>(path, options?)`                     | Delete                  |
| `head`     | `this.api.head(path, options?)`                          | Head check              |

## Path Parameters

Interpolate path params directly in template literals.

```typescript
getServer(id: string): Observable<ServerDto> {
    return this.api.get<ServerDto>(`/server/${id}`);
}
```

Wrap ids in `encodeURIComponent` only when the ids can contain URL-unsafe characters. For safe slug ids, keep `` `/foo/${id}` `` plain.

## Query Parameters

Always use `HttpParams` — never concatenate query strings into the URL.

```typescript
import { HttpParams } from '@angular/common/http';

getLogs(filters: { search?: string; level?: string; limit?: number }): Observable<LogDto[]> {
    let params = new HttpParams();
    if (filters.search) params = params.set('search', filters.search);
    if (filters.level) params = params.set('level', filters.level);
    if (filters.limit) params = params.set('limit', filters.limit.toString());
    return this.api.get<LogDto[]>('/logs', { params });
}
```

For always-present params, chain `.set()` eagerly:

```typescript
const params = new HttpParams()
    .set('period', period)
    .set('details', details);
```

`HttpParams` is immutable — every `.set()` returns a new instance. Reassign (`params = params.set(...)`) when conditionally adding.

## DTO Types

- Co-locate DTOs with the service inside the same domain directory.
  - **`<domain>-dto.ts`** — request/response payloads and wire-only shapes (e.g. `CreateServerRequest`, `ServerActionResponse`).
- Reuse existing types — check if the type already exists before creating a new one.
- Each `core/services/api/<domain>/` folder has a barrel (`index.ts`) that re-exports the API service and DTOs. Consumers import from the barrel, not from individual files.
- Export types from the DTO file, not from the service file.

## Side Effects

Domain API classes are **purely declarative** — one method, one HTTP call, one `Observable<T>`. Do **not** add:

- Error handling, `catchError`, toast notifications.
- Caching, retry, debounce, or `shareReplay`.
- State mutations or signal writes.
- Logging beyond what `BaseService` already does.

Those concerns belong in the paired `<domain>-store.ts`.

## Anti-patterns

- ❌ Injecting `HttpClient` directly — must go through `Api`.
- ❌ Returning `Promise<T>` or `toPromise()` — return `Observable<T>`.
- ❌ Building URLs with string concatenation or `?foo=${x}&bar=${y}` — use `HttpParams`.
- ❌ Registering the service in an `NgModule` `providers` array — always `providedIn: 'root'`.
- ❌ Adding business logic, error handling, or caching in the API class — push it into the store.
- ❌ Spreading one domain across multiple `*-api.ts` files — one domain, one service.
