# Dependency Injection — `inject()` Function Standard

All Angular-decorated classes (`@Component`, `@Directive`, `@Pipe`, `@Injectable`) must use the `inject()` function for dependency injection. Constructor-based injection is **not allowed** in new or modified code.

---

## Pattern

```typescript
import { inject } from '@angular/core';

@Component({ ... })
export class MyComponent {
  private myService = inject(MyService);
  private router = inject(StateService);
}
```

## Rules

1. **All DI parameters** must be `inject()` field initializers, not constructor parameters
2. **`@Inject(TOKEN)`** becomes `inject(TOKEN)`
3. **`@Optional()`** becomes `inject(Service, { optional: true })`
4. **Access modifiers** are preserved on the field (`private`, `protected`, `public`, `readonly`)
5. **Constructor body logic** that depends only on injected services can often become a field initializer; otherwise move it to `ngOnInit`
6. **Remove empty constructors** — if the constructor has no body after migration, delete it entirely
7. **Remove `ComponentFactoryResolver`** injections (deprecated, handled by AOT)
8. **Plain (non-decorated) classes** that receive dependencies as regular constructor parameters are NOT subject to this rule — `inject()` only works in an Angular injection context

## Scope

- Applies to all files under `src/app/` except `.spec.ts` test files
- When modifying a file that still uses constructor injection, migrate it as part of the change

## Import

Merge `inject` into the existing `@angular/core` import. Remove `Inject`, `Optional`, and `ComponentFactoryResolver` from imports if no longer used.

```typescript
// Good
import { Component, inject, OnInit } from '@angular/core';

// Bad — separate import
import { inject } from '@angular/core';
import { Component, OnInit } from '@angular/core';
```
