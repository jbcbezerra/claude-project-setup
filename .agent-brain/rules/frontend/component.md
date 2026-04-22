# Component Authoring — Rules & Best Practices

How to write Angular components: base class, dependency injection, and signals.

> **Canonical skeleton:** [patterns/frontend/base-component.md](../../patterns/frontend/base-component.md). This rule says *what* must hold; the pattern shows *the exact file shape* and variations.

---

## BaseComponent Extension

All Angular components extend a project-local `BaseComponent` (see [pattern](../../patterns/frontend/base-component.md)). The base class injects the project's `Logger` and emits a standard init debug line, so every component gets both without per-class wiring.

### Rules

1. Every `@Component` class `extends BaseComponent`.
2. If the component has a constructor, call `super()` as the first line.
3. Use `this.logger` for all logging — never inject `Logger` separately in components.

### Anti-patterns

```typescript
// ❌ Component without BaseComponent
@Component({ ... })
export class MyComponent { }

// ❌ Injecting Logger when BaseComponent already provides it
export class MyComponent extends BaseComponent {
  private readonly logger = inject(Logger); // already on BaseComponent
}

// ❌ Missing super() call
export class MyComponent extends BaseComponent {
  constructor() {
    // forgot super()
    this.logger.debug('init');
  }
}
```

### Scope

- Applies to all `@Component` classes under `src/app/`.
- Does **not** apply to `@Injectable`, `@Directive`, or `@Pipe` — services use [BaseService](../../patterns/frontend/base-service.md); directives and pipes don't need a shared base.

---

## Change Detection

Prefer `ChangeDetectionStrategy.OnPush` on every component. With signals this should be the default — `OnPush` + signals gives you fine-grained reactivity without manual `markForCheck()` calls.

---

## Signals

### Input / Output Signals (Angular 17.1+)

Use signal-based `input()` and `output()` instead of decorators:

```typescript
// ✅ Modern
containerId = input<string>();
hideToggle = input(false);             // with default
toggleAction = output<boolean>();

// ❌ Old pattern
@Input() containerId?: string;
@Output() toggleAction = new EventEmitter<boolean>();
```

### Methods → Computed Signals

Methods that derive values from signals or state must be `computed()` signals:

```typescript
// ✅ Computed signal — evaluated once per signal change, memoized
showMainContent = computed(() => this.stateService.includes('app.main'));
isDisabled = computed(() => !this.isEnabled() || this.isLoading());
toggleText = computed(() => this.isOpen() ? 'Close' : 'Open');

// ❌ Method — re-runs every change-detection tick
showMainContent() { return this.stateService.includes('app.main'); }
```

See also `templates.md` — no method calls in display bindings.

### Replace ngOnChanges / ngDoCheck with Computed

```typescript
// ❌ ngOnChanges
@Input() date?: Date;
formattedDate = '';
ngOnChanges(changes: SimpleChanges) {
  if (changes['date']) {
    this.formattedDate = this.date ? formatDate(this.date) : '';
  }
}

// ✅ Computed signal
date = input<Date | null>(null);
formattedDate = computed(() => {
  const d = this.date();
  return d ? formatDate(d) : '';
});
```

### Never Mutate Signals Inside Computed or Effects

Computed signals must be pure derivations — no side effects:

```typescript
// ✅ Pure computed
fullName = computed(() => `${this.firstName()} ${this.lastName()}`);

// ❌ Mutating a signal inside computed
doubledCount = computed(() => {
  this.count.set(this.count() * 2); // NEVER
  return this.count();
});

// ✅ Mutate in event handlers
increment() { this.count.update(c => c + 1); }
```

### Don't Use Signals for Static Values

```typescript
// ✅ Static value — regular property or const
weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'] as const;
dateFormat = 'YYYY-MM-DD HH:mm:ss';

// ❌ Signal wrapping a value that never changes
weekdays = signal(['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']);
```

### Only Use Computed for Signal-Derived Values

`computed()` must read at least one signal. If the expression is constant, use a plain property:

```typescript
// ❌ No signal dependency — computed is pointless
currentYear = computed(() => new Date().getFullYear());

// ✅ Plain property
currentYear = new Date().getFullYear();

// ✅ Depends on a signal
selectedDate = signal(new Date());
formattedDate = computed(() => formatDate(this.selectedDate()));
```

### Property Initialization

Initialize properties at definition, not in the constructor:

```typescript
// ✅ Initialized at definition
jobGroup: 'ALL' | 'SYSTEM' | 'REPORTS' = 'SYSTEM';
isEnabled = false;
items: string[] = [];

// ❌ Deferred to constructor
constructor() {
  this.jobGroup = 'SYSTEM';
}
```

### Pure Helper Placement

Helpers that derive a value from their arguments — no `this`, no signals, no side effects — are module-level `const` arrow functions. They never live inside the class.

- **Used by one file only** → declare below the class, at the bottom of that file.
- **Used by two or more files in the same component subtree** → extract to `{component}-utils.ts` at the nearest common ancestor's component root. Each consumer imports from it via a relative path. See [file-organization.md](file-organization.md) — *Sibling-Shared Utilities*.

```typescript
// ✅ Scoped to this file — below the class
export class NodeMetricCardComponent extends BaseComponent { /* … */ }

const toPercentage = (used: number, max: number): number => {
    if (!max) return 0;
    return Math.min(100, Math.round((used / max) * 100));
};
```

```typescript
// ✅ Shared across siblings — hoisted into {ancestor}-utils.ts
export const formatGigaBytes = (gb: number): string =>
    gb >= TB_THRESHOLD ? `${(gb / TB_THRESHOLD).toFixed(1)} TB` : `${gb} GB`;
```

### Cleanup: DestroyRef over OnDestroy

Use `DestroyRef` for manual cleanup instead of `implements OnDestroy`:

```typescript
private readonly destroyRef = inject(DestroyRef);

ngOnInit() {
  const sub = this.service.listen(() => { ... });
  this.destroyRef.onDestroy(() => sub.unsubscribe());
}
```

For RxJS streams, prefer `takeUntilDestroyed()` in the constructor (see component pattern).
