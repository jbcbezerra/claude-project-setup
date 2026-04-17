# Reactive Patterns Modernization

## Context

The codebase has 235+ manual `.subscribe()` calls across 107 files, 125 manual `unsubscribe()` patterns across 60 files, heavy Promise chain usage (`.then()`) instead of Observable operators, almost zero `async` pipe usage, 10+ components using `DoCheck` for manual change detection, and only 5 files using Angular signals. These legacy reactive patterns cause memory leak risks, verbose code, and poor performance.

---

## Phase 1: Subscription Management with takeUntilDestroyed

**Standard:** Replace manual `unsubscribe()` with `takeUntilDestroyed()` from `@angular/core/rxjs-interop`.

**Pattern:**
```typescript
// Before
private sub: Subscription;
ngOnInit() { this.sub = obs$.subscribe(v => this.data = v); }
ngOnDestroy() { this.sub.unsubscribe(); }

// After
private destroyRef = inject(DestroyRef);
ngOnInit() {
  obs$.pipe(takeUntilDestroyed(this.destroyRef)).subscribe(v => this.data = v);
}
```

**Scope:** 60 files with manual `unsubscribe()` patterns.

**Priority files** (most subscriptions):
- `src/app/error-list/error-list.component.ts`
- `src/app/administration/deployment/deployment.component.ts`
- `src/app/administration/argos/argos.component.ts`
- `src/app/trees-viewer/trees-viewer.component.ts`

---

## Phase 2: Async Pipe Adoption

Replace manual `.subscribe()` + class property assignment with `async` pipe in templates.

**Pattern:**
```typescript
// Before (component)
data: SomeType[];
ngOnInit() { this.service.getData().subscribe(d => this.data = d); }
// Before (template)
<div *ngFor="let item of data">

// After (component)
data$ = this.service.getData();
// After (template)
@for (item of data$ | async; track item.id) {
```

**Target:** Simple data-loading patterns where a subscription sets a property used only in the template. Start with components that have 1-2 simple subscriptions.

---

## Phase 3: Promise-to-Observable Migration

Many components call `.then()` on service methods that return Observables (via `.toPromise()` or `lastValueFrom()`).

**Pattern:**
```typescript
// Before
this.api.getData().then(result => { this.data = result; });

// After
this.api.getData().pipe(
  takeUntilDestroyed(this.destroyRef)
).subscribe(result => { this.data = result; });
// Or better: use async pipe (Phase 2)
```

**Priority:** Components with multiple chained `.then()` calls where error handling is inconsistent.

---

## Phase 4: Remove DoCheck Patterns

10+ components implement `DoCheck` / `ngDoCheck()` for manual change detection — a legacy pattern from fighting the change detection system.

**Key files:**
- `src/app/error-list/error-list.component.ts`
- `src/app/administration/ldap/ldap.component.ts`
- `src/app/administration/argos/argos.component.ts`
- `src/app/administration/deployment/deployment.component.ts`

**Fix:** Analyze what each `DoCheck` is detecting, then replace with:
- Signals or `computed()` for derived state
- `distinctUntilChanged()` on Observables for value change detection
- `OnPush` change detection + explicit `markForCheck()` or signal-based reactivity

Each `DoCheck` removal requires case-by-case analysis.

---

## Phase 5: Expand Signal Usage

Follow the existing pattern in `src/app/shared/services/base-state.ts` and the 5 files already using signals.

**Targets:**
- Simple component state: booleans (loading, expanded), counters, selected items
- Derived state: use `computed()` instead of recalculating in methods
- Input/Output: use `input()` and `output()` signal-based APIs for new components

**Pattern:**
```typescript
// Before
isLoading = false;
get filteredItems() { return this.items.filter(i => i.active); }

// After
isLoading = signal(false);
items = signal<Item[]>([]);
filteredItems = computed(() => this.items().filter(i => i.active));
```

---

## Execution Order

1. Phase 1 (takeUntilDestroyed) — lowest risk, biggest cleanup
2. Phase 2 (async pipe) — requires template changes, do alongside control flow migration
3. Phase 3 (Promise-to-Observable) — requires understanding each call chain
4. Phase 4 (DoCheck removal) — case-by-case, do when touching those components
5. Phase 5 (signals) — for new code and components being refactored

---

## Verification

Per component batch:
1. `ng build` — compiles
2. No memory leaks: navigate away from component, verify subscriptions are cleaned up (use Angular DevTools)
3. Data still loads and updates correctly
4. `npm run test:prod` — tests pass
