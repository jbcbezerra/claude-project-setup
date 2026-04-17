# AOT & Build Configuration

## Context

The project runs with `aot: false` in both development and production, meaning Angular ships the JIT compiler (~1MB) to the browser, `buildOptimizer` cannot function, template errors are hidden until runtime, and `strictTemplates` cannot be enabled. Enabling AOT is the single most impactful modernization change, but the codebase has 6 critical AOT-incompatible patterns that must be resolved first.

The user has previously attempted enabling AOT and encountered failures with dialog rendering and ngx-toastr.

---

## AOT Blockers (must fix before enabling AOT)

### Blocker 1: Custom Parser from @angular/compiler (CRITICAL)

**Files:**
- `src/app/nj-parser.service.ts` — extends `Parser` from `@angular/compiler`
- `src/main.ts` — provides `Parser` override at bootstrap

**Problem:** `@angular/compiler` is NOT included in AOT bundles. The `NjParserService` extends `Parser` and is injected at bootstrap:
```typescript
bootstrapModule(AppModule, {
  providers: [{ provide: Parser, useFactory: NjParserService.getInstance }],
})
```

**Fix:** Determine what the custom parser does (likely custom template expression parsing). Either:
- Remove the custom parser if no longer needed
- Move the custom logic into a service that doesn't depend on `@angular/compiler`

---

### Blocker 2: ComponentFactoryResolver in Dialog Service (CRITICAL)

**Files:**
- `src/app/shared/components/dialogs/nj-dialog/nj-dialog.service.ts` (lines 20, 142-145, 153)
- `src/app/shared/components/dialogs/nj-dialog/nj-dialog-options.ts` (line 7)

**Problem:** `NjDialogService` uses the deprecated `resolveComponentFactory()` API:
```typescript
componentFactory = this.componentFactoryResolver.resolveComponentFactory(component);
this.currentComponents[id] = viewContainerRef.createComponent(componentFactory);
```

Also accesses `__annotations__` metadata (lines 224-234) which is stripped in AOT.

**Fix:** Replace with the modern `ViewContainerRef.createComponent(ComponentType)` API (available since Angular 13):
```typescript
// Before
const factory = this.componentFactoryResolver.resolveComponentFactory(component);
viewContainerRef.createComponent(factory);

// After
viewContainerRef.createComponent(component);
```

For selector detection, use Angular's `reflectComponentType()`:
```typescript
import { reflectComponentType } from '@angular/core';
const mirror = reflectComponentType(component);
return mirror?.selector ?? component.name;
```

Remove `ComponentFactoryResolver` injection entirely.

---

### Blocker 3: Runtime Compiler in ModuleCompiler Service (CRITICAL)

**Files:**
- `src/app/shared/services/features/module-compiler.service.ts` (lines 16-40)
- `src/app/shared/services/features/feature-initialization.service.ts` (lines 78-80)

**Problem:** Uses `Compiler.compileModuleAndAllComponentsAsync()` which requires JIT:
```typescript
this.compiler.compileModuleAndAllComponentsAsync(mod).then(factories => { ... })
```

**Fix:** Replace with standard lazy loading. Modern Angular can load standalone components or modules directly:
```typescript
// Use dynamic import + createNgModule or direct component reference
const module = await import('./path/to/feature.module');
const moduleRef = createNgModule(module.FeatureModule, this.injector);
```
Or migrate feature modules to standalone components with route-based lazy loading.

---

### Blocker 4: Dynamic Component() Decorator (CRITICAL)

**Files:**
- `src/app/trees-viewer/nj-custom-report/dynamic-component.service.ts` (lines 13-26)

**Problem:** Creates components at runtime using the `Component()` decorator function:
```typescript
const component = Component({ standalone: true, selector, template, ... })(class {});
viewContainerRef.createComponent(component);
```
AOT cannot compile dynamically-created templates.

**Fix:** This is the hardest pattern to replace. Options:
1. Pre-define a set of known template components and select at runtime
2. Use `DomSanitizer` + `innerHTML` for simple HTML rendering (no Angular bindings)
3. If templates need Angular features, use a registry of pre-compiled components

---

### Blocker 5: ComponentFactoryResolver in Error List (HIGH)

**Files:**
- `src/app/error-list/error-list-item/error-list-item.component.ts` (lines 41, 73-74)

**Problem:** Same deprecated pattern as dialog service:
```typescript
const componentFactory = value.mod.componentFactoryResolver.resolveComponentFactory(value.component);
this.plungerSlot!.createComponent(componentFactory);
```

**Fix:** Same as Blocker 2 — use `ViewContainerRef.createComponent(ComponentType)` directly.

---

### Blocker 6: new Function() in Custom Reports (MEDIUM)

**Files:**
- `src/app/trees-viewer/nj-custom-report/nj-custom-report-tile-parameters.model.ts` (lines 38-44, 59)
- `src/app/trees-viewer/nj-custom-report/nj-custom-report-tile/nj-custom-report-tile.component.ts` (lines 107, 205)
- `src/app/trees-viewer/nj-custom-report/nj-custom-report-tile-wizard/nj-custom-report-tile-wizard.component.ts` (lines 102, 276)

**Problem:** Uses `new Function('$scope', 'return ' + expr + ';')` for dynamic expression evaluation.

**Fix:** This technically works with AOT but fails under strict CSP. For now, mark as acceptable risk. Long-term: replace with a safe expression parser (e.g., jmespath which is already a dependency).

---

### ngx-toastr Issues (MEDIUM)

**Files:**
- `src/app/notifications/notifications.module.ts` (lines 12-13) — uses `forwardRef()` + string token
- `src/app/notifications/notifications.service.ts` (lines 20-22) — `injector.get('ToastsService')` string-based token

**Problem:** String-based injection token `'ToastsService'` may not resolve correctly in AOT. The `forwardRef()` is AOT-compatible but the string token is fragile.

**Fix:** Replace string token with an `InjectionToken`:
```typescript
export const TOASTS_SERVICE = new InjectionToken<ToastsService>('ToastsService');

// In module
{ provide: TOASTS_SERVICE, useExisting: forwardRef(() => ToastrService) }

// In service
private toastsService = inject(TOASTS_SERVICE);
```

---

## Build Configuration Changes (after blockers are resolved)

### Step 1: Enable AOT
**File:** `angular.json`
- Line 64: `"aot": true` (options level)
- Line 90: `"aot": true` (production config)

### Step 2: Enable Build Optimizer
**File:** `angular.json`
- Line 93: `"buildOptimizer": true` (production)
- Line 92: `"vendorChunk": false` (production)
- Line 89: `"namedChunks": false` (production)

### Step 3: Tighten Budgets
**File:** `angular.json`
- Warning: 5MB, Error: 12MB (currently 12MB/25MB)

### Step 4: TypeScript Config
**File:** `tsconfig.json`
- Remove `"emitDecoratorMetadata": true` (line 103)
- Set `"isolatedModules": true` (line 85)
- Remove `"noStrictGenericChecks": true` (line 123)
- Uncomment `angularCompilerOptions` block (lines 126-135) to enable `strictTemplates`

---

## Execution Order

1. Fix Blocker 1 (custom parser) — required for AOT to compile at all
2. Fix Blocker 2 (dialog service) — required for app to function
3. Fix Blocker 5 (error-list) — same pattern, do alongside Blocker 2
4. Fix Blocker 3 (module compiler) — required for feature loading
5. Fix ngx-toastr string token — required for notifications
6. Enable AOT in angular.json
7. Fix any template compilation errors that surface
8. Enable buildOptimizer and other config changes
9. Fix Blocker 4 (dynamic components) — most complex, can follow later
10. Address Blocker 6 (new Function) — acceptable risk for now

---

## Verification

1. `npm run build` with AOT enabled — must compile without errors
2. `npm run build:prod` — verify reduced bundle size (expect 15-25% reduction)
3. Manual test: open a dialog (any dialog) — must render correctly
4. Manual test: trigger a toast notification — must display
5. Manual test: navigate to custom reports — tiles must render
6. Manual test: error-list with plugins — plugin slots must render
7. `npm run test:prod` — all unit tests pass

---

## Risk Assessment

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Template errors surface in AOT | HIGH | These are pre-existing bugs — fix each one |
| Custom report tiles break (Blocker 4) | HIGH | May need phased approach — keep JIT fallback for custom reports initially |
| Feature loading breaks (Blocker 3) | HIGH | Test all lazy-loaded routes after migration |
| Third-party libs incompatible | LOW | ngx-toastr 17 and PrimeNG 17 support AOT |
