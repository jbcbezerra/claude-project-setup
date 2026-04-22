# Api (HTTP Client Wrapper)

Project-wide wrapper around Angular's `HttpClient` that every domain API service injects. Centralizes request defaults (base URL prefix, headers, `take(1)`, endpoint normalization) so domain services stay declarative — one method, one HTTP call, one `Observable<T>`.

Two files:

- **`base-api.ts`** — abstract generic class with the typed CRUD surface.
- **`api.ts`** — concrete singleton that sets `apiEndpoint` and is the class every domain API injects.

Pairs with [rules/frontend/api-services.md](../../rules/frontend/api-services.md) — the rule mandates injecting `Api` (never `HttpClient` directly); this pattern is the file that `Api` lives in.

---

## Skeleton — `base-api.ts`

```typescript
// src/app/core/http/base-api.ts

import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Observable, take } from 'rxjs';
import { inject } from '@angular/core';

export type IApiCrudActions = {
    get(url: string, options?: HttpOptions): Observable<unknown>;

    getAll(url: string, options?: HttpOptions): Observable<unknown>;

    post(url: string, data?: unknown, options?: HttpOptions): Observable<unknown>;

    delete(url: string, data?: unknown, options?: HttpOptions): Observable<unknown>;

    put(url: string, data?: unknown, options?: HttpOptions): Observable<unknown>;

    patch(url: string, data?: unknown, options?: HttpOptions): Observable<unknown>;
};

export type HttpOptions = Record<
    string,
    string | (HttpHeaders | Record<string, string>) | (HttpParams | Record<string, string>)
>;

export abstract class BaseApi implements IApiCrudActions {
    readonly jsonStreamType: string = 'application/json';
    readonly octetStreamType: string = 'application/octet-stream';
    readonly plainStreamType: string = 'text/plain';

    protected abstract readonly apiEndpoint: string;
    private http: HttpClient = inject(HttpClient);

    head(endpoint: string, options?: HttpOptions): Observable<unknown> {
        return this.http
            .head(`${this.apiEndpoint}${this.checkAndPrepareEndpoint(endpoint)}`, this.createOptions(options))
            .pipe(take(1));
    }

    get<T>(endpoint: string, options?: HttpOptions): Observable<T> {
        return this.http
            .get<T>(`${this.apiEndpoint}${this.checkAndPrepareEndpoint(endpoint)}`, this.createOptions(options))
            .pipe(take(1));
    }

    getAll<T>(endpoint: string, options?: HttpOptions): Observable<T[]> {
        return this.http
            .get<T[]>(`${this.apiEndpoint}${this.checkAndPrepareEndpoint(endpoint)}`, this.createOptions(options))
            .pipe(take(1));
    }

    post<T>(endpoint: string, data?: unknown, options?: HttpOptions): Observable<T> {
        return this.http
            .post<T>(`${this.apiEndpoint}${this.checkAndPrepareEndpoint(endpoint)}`, data, this.createOptions(options))
            .pipe(take(1));
    }

    delete<T>(endpoint: string, options?: HttpOptions): Observable<T> {
        return this.http
            .delete<T>(`${this.apiEndpoint}${this.checkAndPrepareEndpoint(endpoint)}`, this.createOptions(options))
            .pipe(take(1));
    }

    put<T>(endpoint: string, data?: unknown, options?: HttpOptions): Observable<T> {
        return this.http
            .put<T>(`${this.apiEndpoint}${this.checkAndPrepareEndpoint(endpoint)}`, data, this.createOptions(options))
            .pipe(take(1));
    }

    patch<T>(endpoint: string, data?: unknown, options?: HttpOptions): Observable<T> {
        return this.http
            .patch<T>(`${this.apiEndpoint}${this.checkAndPrepareEndpoint(endpoint)}`, data, this.createOptions(options))
            .pipe(take(1));
    }

    private createOptions(options?: HttpOptions) {
        const httpOptions: HttpOptions = {};

        httpOptions['headers'] = this.createHeaders();
        httpOptions['params'] = this.createParams();

        if (options) {
            Object.entries(options).forEach(([key, value]) => {
                httpOptions[key] = value as HttpOptions[string];
            });
        }

        return httpOptions;
    }

    private createHeaders(headers?: HttpHeaders) {
        let httpHeaders = new HttpHeaders();

        httpHeaders = httpHeaders.set('Content-Type', this.jsonStreamType);
        httpHeaders = httpHeaders.set('Accept', this.jsonStreamType);

        if (headers) {
            Object.entries(headers).forEach(([key, value]: [string, string]) => {
                httpHeaders = httpHeaders.set(key, value);
            });
        }
        return httpHeaders;
    }

    private createParams(params?: HttpParams) {
        let httpParams = new HttpParams();

        if (params) {
            Object.entries(params).forEach(([key, value]: [string, string]) => {
                httpParams = httpParams.set(key, value);
            });
        }
        return httpParams;
    }

    private checkAndPrepareEndpoint(endpoint: string) {
        if (endpoint.startsWith('/')) {
            return endpoint;
        } else {
            return `/${endpoint}`;
        }
    }
}
```

---

## Skeleton — `api.ts`

```typescript
// src/app/core/http/api.ts

import { Injectable } from '@angular/core';
import { BaseApi } from './base-api';

@Injectable({
    providedIn: 'root',
})
export class Api extends BaseApi {
    apiEndpoint = 'api';
}
```

Keep `Api` this small on purpose — the concrete class only pins the base URL prefix. All behavior lives in `BaseApi`, so adding a second wrapper (e.g. `ExternalApi extends BaseApi { apiEndpoint = 'https://third-party.example.com/v1'; }`) is a two-line change.

---

## Design Rationale

- **Single entry point.** Domain API services inject `Api`, not `HttpClient`. Request defaults (auth, base URL, `take(1)`) are set in one place and can't drift per-service.
- **`take(1)` everywhere.** Every HTTP method pipes `take(1)` so callers never have to remember — one request, one emission, auto-complete. Prevents leaks when templates subscribe.
- **Generic base.** `BaseApi` is abstract + generic so the same machinery backs both internal and external API wrappers when a project needs more than one.
- **Endpoint normalization.** `checkAndPrepareEndpoint` guarantees `apiEndpoint + endpoint` produces a valid URL regardless of whether callers pass `'/users'` or `'users'`.
- **Typed `HttpOptions`.** The `HttpOptions` type is deliberately loose (`Record<string, ...>`) because Angular's `HttpClient` options object is position- and key-dependent; locking it tighter would make the common cases more verbose.

---

## When to use

- Every Angular project with more than a handful of HTTP calls.
- Drop in at project start or during a refactor sweep that consolidates scattered `HttpClient` usage.
- Every domain API service (`core/services/api/<domain>/<domain>-api.ts`) injects `Api` — no direct `HttpClient` use anywhere outside `base-api.ts`.

---

## Usage from a Domain API Service

```typescript
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { Api } from '../../../http/api';
import { BaseService } from '../../../../shared/services/base-service';
import { ServerActionResponse, ServerCreateRequestDto, ServerCreateResponseDto } from './server-dto';
import { Server } from '../../../../domain/servers/pages/servers-page/models';

@Injectable({
    providedIn: 'root',
})
export class ServerApi extends BaseService {
    private readonly api = inject(Api);

    // ========== /servers ==========
    getServers(): Observable<Server[]> {
        return this.api.get<Server[]>('/servers');
    }

    createServer(payload: ServerCreateRequestDto): Observable<ServerCreateResponseDto> {
        return this.api.post<ServerCreateResponseDto>('/servers', payload);
    }

    // ========== /servers/{node}/{vmid} ==========
    deleteServer(node: string, vmid: string | number): Observable<ServerActionResponse> {
        return this.api.delete<ServerActionResponse>(`/servers/${node}/${vmid}`);
    }
}
```

Full conventions for domain services: [rules/frontend/api-services.md](../../rules/frontend/api-services.md).

---

## Variations

### Auth headers via `HttpInterceptor` (preferred)

Don't bake auth into `createHeaders()`. Register an `HttpInterceptor` in `providers` so the token is attached at a single choke point without coupling `BaseApi` to the auth system:

```typescript
// src/app/core/http/auth-interceptor.ts
import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { AuthStore } from '../auth/auth-store';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
    const token = inject(AuthStore).token();
    return next(token ? req.clone({ setHeaders: { Authorization: `Bearer ${token}` } }) : req);
};
```

Wire it in `app.config.ts` via `provideHttpClient(withInterceptors([authInterceptor]))`.

### Multiple base URLs

Introduce sibling subclasses of `BaseApi` — one per upstream — and inject the right one per domain service:

```typescript
@Injectable({ providedIn: 'root' })
export class Api extends BaseApi {
    apiEndpoint = 'api';
}

@Injectable({ providedIn: 'root' })
export class MetricsApi extends BaseApi {
    apiEndpoint = 'metrics';
}
```

Domain services pick whichever fits: `private readonly api = inject(MetricsApi);`.

### Environment-driven base URL

If the base URL changes per environment, pull it from `environment.ts` in the concrete `Api`, never in `BaseApi`:

```typescript
import { environment } from '../../../environments/environment';

@Injectable({ providedIn: 'root' })
export class Api extends BaseApi {
    apiEndpoint = environment.apiBaseUrl;
}
```

### Response-type overrides (blobs, text, server-sent streams)

For non-JSON responses, pass `responseType` through `HttpOptions`. The `octetStreamType` / `plainStreamType` constants on `BaseApi` document the common cases:

```typescript
downloadReport(id: string): Observable<Blob> {
    return this.api.get<Blob>(`/reports/${id}`, { responseType: 'blob' });
}
```

---

## Anti-patterns

- ❌ Injecting `HttpClient` outside `base-api.ts`. `Api` is the single entry point — everything else goes through it.
- ❌ Subclassing `BaseApi` inside a domain service. Only `core/http/*.ts` files extend `BaseApi`. Domain services extend [BaseService](base-service.md) and inject `Api`.
- ❌ Adding domain logic to `BaseApi` (retries, caching, toasts, error handling). `BaseApi` is a thin transport layer — cross-cutting concerns go in interceptors; domain concerns go in stores.
- ❌ Dropping the `take(1)`. It's a load-bearing default — removing it leaks subscriptions in templates that `async` pipe onto the result.
- ❌ Hardcoding URLs with the base prefix in domain services (`/api/servers`). Pass only the path (`/servers`) — `BaseApi` prepends `apiEndpoint`.
