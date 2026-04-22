# BaseService

Project-wide base class for every Angular `@Injectable`. Provides a scoped `Logger` and emits a standard debug line on construction so session logs always show which services initialized.

Pairs with [rules/frontend/api-services.md](../../rules/frontend/api-services.md) — API services extend this so every outbound call has a ready-to-use logger and a uniform init log line.

---

## Skeleton

```typescript
// src/app/shared/services/base-service.ts

import { inject } from '@angular/core';
import { Logger } from '../../core/logging/logger';

export abstract class BaseService {
    readonly logger = inject(Logger);

    constructor() {
        this.logger.debug(`${this.constructor.name} initialized`);
    }
}
```

Keep it this small on purpose. Every service that extends it pays the cost of anything added here, so the base stays trivial: one injected dependency, one init log line.

---

## When to use

Extend `BaseService` in:

- All domain API services under `core/services/api/<domain>/<domain>-api.ts`.
- All stateful singletons that benefit from a scoped logger (stores, caches, orchestrators).
- Any `@Injectable({ providedIn: 'root' })` class where a uniform init log line is valuable.

Skip `BaseService` for:

- Pure functional services with no side effects and no logging needs.
- Services where inheritance would conflict with a different base class (e.g. framework-provided abstracts).

---

## Usage

```typescript
import { Injectable, inject } from '@angular/core';
import { BaseService } from '<relative-path>/shared/services/base-service';
import { Api } from '../../../http/api';

@Injectable({
    providedIn: 'root',
})
export class JobApi extends BaseService {
    private readonly api = inject(Api);

    getJobs(): Observable<JobDto[]> {
        return this.api.get<JobDto[]>('/jobs');
    }
}
```

If your service needs its own constructor, call `super()` as the first line so the base-class debug log still fires:

```typescript
@Injectable({ providedIn: 'root' })
export class SessionStore extends BaseService {
    constructor() {
        super();
        this.hydrateFromStorage();
    }
}
```

---

## Dependency

Requires a project-level `Logger` service. See [logger.md](logger.md) for a reference implementation. The only contract `BaseService` needs is a `debug(message: unknown, ...params: unknown[]): void` method.

---

## Variations

### Scoped log prefix

If you want every log call from a service to carry the class name automatically, expose a thin wrapper instead of the raw logger:

```typescript
export abstract class BaseService {
    private readonly _logger = inject(Logger);
    readonly logger = {
        debug: (msg: unknown, ...rest: unknown[]) => this._logger.debug(`[${this.constructor.name}] ${msg}`, ...rest),
        info:  (msg: unknown, ...rest: unknown[]) => this._logger.info (`[${this.constructor.name}] ${msg}`, ...rest),
        warn:  (msg: unknown, ...rest: unknown[]) => this._logger.warn (`[${this.constructor.name}] ${msg}`, ...rest),
        error: (msg: unknown, ...rest: unknown[]) => this._logger.error(`[${this.constructor.name}] ${msg}`, ...rest),
    };

    constructor() {
        this.logger.debug('initialized');
    }
}
```

Only adopt this if the codebase is large enough that raw `logger.debug('X did Y')` calls are losing context in the console.
