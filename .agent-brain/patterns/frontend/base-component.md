# BaseComponent

Project-wide base class for every Angular `@Component`. Provides a scoped `Logger` and emits a standard debug line on construction so session logs always show which components initialized.

Pairs with [rules/frontend/component.md](../../rules/frontend/component.md) — the rule says every component must extend this; the pattern is the file it extends.

---

## Skeleton

```typescript
// src/app/shared/components/base-component.ts

import { inject } from '@angular/core';
import { Logger } from '../../core/logging/logger';

export abstract class BaseComponent {
    readonly logger = inject(Logger);

    constructor() {
        this.logger.debug(`${this.constructor.name} initialized`);
    }
}
```

That's the entire file — no additions, no lifecycle hooks, no cleanup logic. Keep it trivially small on purpose: every component in the codebase extends it, so anything added here becomes a per-component tax.

---

## When to use

- Adopt once, at the start of the project or during a refactor sweep.
- Every `@Component` class in `src/app/` should extend it — no exceptions.

Does **not** apply to `@Injectable`, `@Directive`, or `@Pipe` — services use [BaseService](base-service.md); directives and pipes generally don't need a shared base.

---

## Usage

```typescript
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { BaseComponent } from '<relative-path>/shared/components/base-component';

@Component({
    selector: 'app-my-component',
    templateUrl: './my-component.html',
    styleUrl: './my-component.scss',
    changeDetection: ChangeDetectionStrategy.OnPush,
})
export class MyComponent extends BaseComponent {
    // this.logger is available from BaseComponent
}
```

If your component has its own constructor, call `super()` as the first line so the base-class debug log still fires:

```typescript
export class MyComponent extends BaseComponent {
    constructor() {
        super();
        // component-specific init
    }
}
```

---

## Dependency

Requires a project-level `Logger` service. See [logger.md](logger.md) for a reference implementation. The only contract `BaseComponent` needs is a `debug(message: unknown, ...params: unknown[]): void` method — you can back it by any logger that exposes one.

---

## Variations

### Change-detection defaults

If every component in the project uses `ChangeDetectionStrategy.OnPush` (recommended with signals), you **cannot** apply it in `BaseComponent` — `@Component` metadata doesn't inherit. Instead, enforce via an ESLint rule or include `changeDetection: ChangeDetectionStrategy.OnPush` in the canonical component pattern/snippet.

### With destroy cleanup

If you want centralized cleanup, add `DestroyRef` here rather than each component injecting it separately:

```typescript
import { DestroyRef, inject } from '@angular/core';
import { Logger } from '../../core/logging/logger';

export abstract class BaseComponent {
    protected readonly destroyRef = inject(DestroyRef);
    readonly logger = inject(Logger);

    constructor() {
        this.logger.debug(`${this.constructor.name} initialized`);
    }
}
```

Only do this if nearly every component subscribes to something. Otherwise keep it out and have components inject `DestroyRef` on demand.
