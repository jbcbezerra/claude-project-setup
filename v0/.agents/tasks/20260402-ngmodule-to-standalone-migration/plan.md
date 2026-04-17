# NgModule to Standalone Component Migration

## Context

The project has ~185 standalone components and ~180 NgModule-based components — a mixed architecture from gradual migration. Angular 17 recommends standalone as the default. Consolidating to standalone simplifies the module graph, enables better tree-shaking, and removes boilerplate.

---

## Strategy: Leaf-First Migration

Migrate from the leaves of the dependency tree inward to avoid breaking imports.

### Phase 1: Single-Component Modules

Modules that exist only to declare one component and re-export it. These are pure boilerplate.

**Pattern:**
```typescript
// Before: feature.module.ts
@NgModule({ declarations: [FeatureComponent], imports: [...], exports: [FeatureComponent] })
export class FeatureModule {}

// After: feature.component.ts
@Component({ standalone: true, imports: [...] })
export class FeatureComponent {}
// Delete feature.module.ts
```

**Action:** Run Angular schematic as a starting point:
```bash
ng generate @angular/core:standalone
```

Select "Convert all components, directives and pipes to standalone" first, then "Remove unnecessary NgModule classes".

### Phase 2: Shared Components (`src/app/shared/components/`)

High-value targets — used across many features. ~12 module files in shared/components.

Priority order:
1. Simple presentational components (pipes, directives)
2. Components with few dependencies
3. Dialog-related components (after AOT migration)

### Phase 3: Feature Modules

Convert lazily-loaded feature modules to standalone route configs:

```typescript
// Before: loadChildren: () => import('./feature.module').then(m => m.FeatureModule)
// After:  loadChildren: () => import('./feature.routes').then(m => m.FEATURE_ROUTES)
```

Or use `loadComponent` for single-component routes:
```typescript
loadComponent: () => import('./feature.component').then(m => m.FeatureComponent)
```

### Phase 4: Root Module Simplification

After most modules are standalone:
- Slim down `app.module.ts` imports
- Move toward `bootstrapApplication()` in `main.ts` (final step, after UI-Router migration)

---

## Files to Change

- ~180 `.module.ts` files (to be deleted or converted)
- Corresponding `.component.ts` files (add `standalone: true` and `imports`)
- Parent modules that import the converted modules (update imports)
- Route configurations (update `loadChildren` to `loadComponent` where applicable)

---

## Constraints

- Do NOT convert modules that are part of the UI-Router migration scope (separate task)
- Do NOT convert the root `AppModule` yet (depends on UI-Router removal)
- Migrate in small batches — each batch should be a buildable, testable state
- Keep `CommonModule` imports where needed for pipes (`async`, `date`, `keyvalue`, etc.)

---

## Verification

Per batch:
1. `ng build` — compiles without errors
2. No runtime errors in browser console for affected features
3. `npm run test:prod` — tests pass
4. Verify lazy-loaded routes still load correctly
