# Angular General

Project-wide Angular conventions that apply across all decorated classes (`@Component`, `@Directive`, `@Pipe`, `@Injectable`).

> Adapt paths, selector prefix, and base-class names to your project. The rules themselves are framework-level and meant to be portable across Angular codebases.

---

## Standalone Only — No NgModules

All components, directives, and pipes are standalone. `standalone: true` is implicit on Angular 19+; keep it explicit on older versions. No `@NgModule` declarations anywhere. Services are provided directly — never registered through a module.

### Provider Placement

| Scope | Where to provide |
|-------|-----------------|
| App-wide singleton | `providedIn: 'root'` on the `@Injectable` |
| Route-scoped | `providers` array in the route config |
| Component-scoped | `providers` array on the `@Component` |

```typescript
// ✅ Singleton service
@Injectable({ providedIn: 'root' })
export class AuthService { }

// ✅ Component-scoped state
@Component({
  providers: [JobListState],
})
export class JobListComponent { }

// ✅ Route-scoped
export const routes: Routes = [
  { path: '', component: DashboardComponent, providers: [DashboardGuard] },
];
```

### Anti-patterns

```typescript
// ❌ No NgModules
@NgModule({
  declarations: [MyComponent],
  imports: [CommonModule],
})
export class MyModule { }

// ❌ No declarations array
// ❌ No entryComponents
```

---

## Dependency Injection — `inject()` Function

All Angular-decorated classes (`@Component`, `@Directive`, `@Pipe`, `@Injectable`) use the `inject()` function for dependency injection. Constructor-based injection is not allowed in new or modified code.

### Pattern

```typescript
import { Component, inject } from '@angular/core';

@Component({ ... })
export class MyComponent {
  private readonly myService = inject(MyService);
  private readonly router = inject(Router);
}
```

### Rules

1. **All DI parameters** are `inject()` field initializers, not constructor parameters.
2. **Always mark injected dependencies as `readonly`** — they should never be reassigned.
3. **`@Inject(TOKEN)`** becomes `inject(TOKEN)`.
4. **`@Optional()`** becomes `inject(Service, { optional: true })`.
5. **Access modifiers** are preserved on the field (`private`, `protected`, `public`).
6. **Constructor body logic** that depends only on injected services can often become a field initializer; otherwise move it to `ngOnInit`.
7. **Remove empty constructors** — if the constructor has no body after migration, delete it entirely.
8. **Remove `ComponentFactoryResolver`** injections (deprecated, handled by AOT).
9. **Plain (non-decorated) classes** that receive dependencies as regular constructor parameters are NOT subject to this rule — `inject()` only works in an Angular injection context.

### Scope

- Applies to all files under `src/app/` except `.spec.ts` test files.
- When modifying a file that still uses constructor injection, migrate it as part of the change.

### Import

Merge `inject` into the existing `@angular/core` import. Remove `Inject`, `Optional`, and `ComponentFactoryResolver` from imports if no longer used.

```typescript
// ✅ Good
import { Component, inject, OnInit } from '@angular/core';

// ❌ Bad — separate import
import { inject } from '@angular/core';
import { Component, OnInit } from '@angular/core';
```

---

## Keep Single-Use Types Inline

When a type is only used by one file, keep it in that file:

```typescript
// ✅ Type only used here — keep inline
type FormState = {
  isEditing: boolean;
  selectedId: string | null;
};
```

Extract to `models/` when:
1. Shared across 2+ files.
2. Domain model used throughout the component tree.

---

## Const Arrow Functions for Utilities

Use `const` arrow functions for standalone utility/helper functions:

```typescript
// ✅ Good
export const formatDate = (date: Date): string =>
  dayjs(date).format('YYYY-MM-DD');

// ❌ Bad — function declaration
export function formatDate(date: Date): string {
  return dayjs(date).format('YYYY-MM-DD');
}
```

**Exception:** Use `function` for generators (`function*`) or recursive functions that reference themselves before assignment.

---

## Imports — Relative Paths Only

Prefer relative paths for every import between source files.

- No `paths` mapping in `tsconfig*.json`.
- No `baseUrl`-based imports (e.g. `app/shared/...`). Even where `baseUrl` is present (e.g. a `cypress/tsconfig.json`), do **not** rely on it for import resolution.
- No webpack/vitest `resolve.alias` entries that fake an alias.

### Correct

```typescript
// from src/app/domain/<area>/pages/<page>/components/<child>/<leaf>/<leaf>.ts
import { SomeComponent } from '../../../../../../shared/components/some-component/some-component';
```

### Anti-patterns

```typescript
// ❌ No 'app/*' alias or baseUrl import style configured project-wide
import { SomeComponent } from 'app/shared/components/some-component/some-component';

// ❌ Don't invent '@app/*' either
import { Foo } from '@app/shared/foo';
```

### When adding tooling (webpack, vite, vitest, cypress)

Do not add path-alias plugins (`tsconfig-paths-webpack-plugin`, `vite-tsconfig-paths`, etc.) to "make `app/...` work". The convention is relative imports — configure the toolchain to match the code, not the other way around.

> If your project has already committed to path aliases, document that decision in an ADR and skip this section.

---

## `type` vs `interface`

Use `type` — not `interface` — when defining pure data shapes (objects with only properties, no methods). This applies to both DTOs and domain models.

### When `interface` is still allowed

- The type defines **methods** (behavioral contracts).
- The type is used with **`implements`** by a class.

```typescript
// Correct — has methods, used with implements
interface QueryObserver {
  onQueryChange(query: string): void;
}
```
