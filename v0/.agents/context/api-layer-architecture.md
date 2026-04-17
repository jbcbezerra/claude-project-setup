# API Layer Architecture

Overview of the Angular HTTP API layer at `src/app/core/services/api/`.

---

## Directory Structure

```
core/services/api/
├── base-api.service.ts          ← Core HTTP service, CRUD methods returning Observable<T>
├── api.service.ts               ← Extends base with file download/upload support
├── connection-test-response.ts  ← Shared connection test response model
├── models/
│   ├── api-crud-actions.interface.ts   ← IApiCrudActions contract
│   ├── http-options.type.ts            ← HttpOptions type for request config
│   └── paging/
│       ├── entity-paging-request.ts    ← Paginated request interface
│       ├── entity-paging-response.ts   ← Generic paginated response interface
│       ├── entity-property-filter.ts   ← Property filter interface
│       ├── entity-sort-entry.ts        ← Sort specification interface
│       └── paging-request.builder.ts   ← Fluent builder for paging requests
└── <domain>/                    ← 45 domain-specific directories
    ├── <domain>-api.service.ts  ← Service class (Injectable, providedIn: root)
    └── *.ts                     ← Co-located type/interface/enum files
```

**~58 service files, ~227 type/interface files** across 45 domain directories.

---

## Base Infrastructure

### BaseApiService (`base-api.service.ts`)

Core HTTP service implementing `IApiCrudActions`. Uses Angular `HttpClient` via `inject()`.

| Method | Signature | Description |
|--------|-----------|-------------|
| `head` | `head(endpoint, options?): Observable<any>` | HTTP HEAD |
| `get` | `get<T>(endpoint, options?): Observable<T>` | HTTP GET |
| `getAll` | `getAll<T>(endpoint, options?): Observable<T[]>` | HTTP GET returning array |
| `post` | `post<T>(endpoint, data?, options?): Observable<T>` | HTTP POST |
| `put` | `put<T>(endpoint, data?, options?): Observable<T>` | HTTP PUT |
| `delete` | `delete<T>(endpoint, options?): Observable<T>` | HTTP DELETE |

All methods: prepend `environment.api_endpoint`, normalize endpoint paths, set default JSON headers, and apply `take(1)` for single-value emission.

### ApiService (`api.service.ts`)

Extends `BaseApiService` with file operations:

| Method | Signature | Description |
|--------|-----------|-------------|
| `getFile` | `getFile(endpoint, options?): Observable<HttpResponse<Blob>>` | Binary file download (GET) |
| `postToGetFile` | `postToGetFile(endpoint, body): Observable<HttpResponse<Blob>>` | Binary file download (POST with body) |

Both return full `HttpResponse` (with headers/status) and use `responseType: 'blob'`.

---

## Domain Services

All domain services follow this pattern:

```typescript
@Injectable({ providedIn: 'root' })
export class <Domain>ApiService {
    readonly apiService: ApiService = inject(ApiService);

    // Methods returning Observable<T>...
}
```

**Conventions:**
- `inject()` function (never constructor injection)
- `readonly apiService` field
- Return `Observable<T>` (never `Promise<T>`)
- `HttpParams` for query parameters (never inline in URL strings)
- `customEncodeURIComponent()` for path parameters
- `FormData` for file uploads with `{ headers: {} }` to override default JSON content-type

**Complexity range:** Simple services have 2-3 methods (e.g., `MailApiService`), complex ones have 30+ (e.g., `ProcessApiService` with 35 methods).

---

## Paging Infrastructure

`PagingRequestBuilder` provides a fluent API for constructing `EntityPagingRequest` objects:

```typescript
const request = new PagingRequestBuilder(formatDateService)
    .page(1)
    .pageSize(10)
    .sortOrder('desc', 'desc', 'eventTime', 'eventTime')
    .filter('search text')
    .wildcardProperties(['message', 'severity'])
    .build();
```

`EntityPagingResponse<T>` wraps paginated results with `resultList: T[]`, `total`, `page`, `pageSize`, `maxPages`, `resultCount`.

---

## Error Handling

### Interceptor Registration

```typescript
// app.module.ts
provideHttpClient(withInterceptors([globalHttpErrorHandlerInterceptor]))
```

Single functional interceptor (`HttpInterceptorFn`). No other interceptors exist.

### Error Flow

```
HTTP Error Response
    ↓
globalHttpErrorHandlerInterceptor
    ├─ Status 0        → setBackendOffline() (or "Request failed" for deployments)
    ├─ Status -1, 504  → setBackendOffline()
    ├─ Status 401, 403 → logout + redirect to login
    ├─ Status 503      → shutdown screen (if NJAMS_DOWN) + setBackendOffline()
    ├─ Status 404      → offline (if clustered) or show "Not found"
    └─ Default         → check against ignored error codes, then notify user
    ↓
NotificationsService.showError(error)
    ├─ ErrorResponse with status → modal dialog (severity-mapped: INFO/WARN/ERROR)
    └─ String/generic            → toast notification
```

**Ignored error codes:** 00017 (password expired), 00190, 00057, 00102

**Excluded URLs** (errors suppressed): usermanagement auth endpoints, notification/message, initialadmin

### ErrorResponse Interface

```typescript
// core/interceptors/global-http-error-handler/error-response.ts
export interface ErrorResponse {
    status: number;
    errorCode: string;
    message: string;
    requestId: string;
    requestNo: number;
    errorSeverity: string;    // INFO, WARN, ERROR, NOLOG
    causeMessage: string;
    stackTrace: string;
}
```

---

## Consumer Patterns

### Pattern 1: Subscribe with `takeUntilDestroyed` (most common — 141 occurrences)

```typescript
private destroyRef = inject(DestroyRef);

this.apiService.getData()
    .pipe(takeUntilDestroyed(this.destroyRef))
    .subscribe(result => { this.data = result; });
```

### Pattern 2: `forkJoin` for parallel requests (15 files)

```typescript
forkJoin([this.apiA.getData(), this.apiB.getConfig()])
    .pipe(takeUntilDestroyed(this.destroyRef))
    .subscribe(([data, config]) => { ... });
```

### Pattern 3: `pipe(map(...))` for data transformation (in adapter services)

```typescript
getSessions(): Observable<Session[]> {
    return this.api.get<SessionDto[]>('/sessions')
        .pipe(map(dtos => toSessionList(dtos)));
}
```

### Pattern 4: State services with NgRx Signals (modern feature modules)

```typescript
@Injectable()
export class FeatureState extends BaseState {
    private readonly api = inject(FeatureApi);
    readonly vm = signalState<FeatureVm>(INIT_STATE);

    onRefresh$ = new Subject<void>();

    constructor() {
        super();
        this.onRefresh$.pipe(
            takeUntilDestroyed(),
            switchMap(() => this.api.getData().pipe(
                tap(data => patchState(this.vm, { data }))
            ))
        ).subscribe();
    }
}
```

### Pattern 5: `firstValueFrom` / `lastValueFrom` (56 files — legacy, declining usage)

```typescript
const data = await firstValueFrom(this.apiService.getData());
```

---

## File Organization Conventions

- **Co-location:** Type files live alongside the service that uses them (not in a centralized types folder)
- **No barrel files:** All imports are explicit paths to individual files
- **Naming:** Services: `<domain>-api.service.ts`, Types: `<entity>.ts`, Enums: `<entity>.enum.ts`, Type collections: `<domain>.types.ts`
- **Flat domains:** Most directories are flat (service + types side-by-side)
- **Hierarchical domains:** Complex features like `usermanagement/` use sub-directories (`authentication/`, `layout/`, `objects/`, `privileges/`)
- **Shared models:** Cross-domain types live in `models/` (paging, CRUD actions, HTTP options)

---

## Related Documentation

- API service conventions: `.agents/rules/api-services.md`
- Migration ADR: `.agents/decisions/ADR-20260401-api-layer-migration.md` (status: Complete)
- Migration history: `.agents/history/20260403-api-migration-workflow-final.md`
