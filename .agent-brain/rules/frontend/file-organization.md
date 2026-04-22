# File Organization

Rules for domain folder structure, component layout, file naming, and module boundaries.

---

## Domain-Level Structure

Domains live in `src/app/domain/`. Each domain has two child directories at its root:

- `pages/` — routable entry points (page-level components).
- `components/` — shared components within this domain (not routed to directly).

Optionally, a domain may also have at its root:

- `{domain}-store.ts` — a domain-wide signal-based state container, when state needs to be shared across multiple components (or across domains).
- `models/` — domain-wide domain types, mappers, and constants used by the store and/or multiple components in the domain.

```
src/app/domain/my-domain/
├── my-domain.routes.ts
├── my-domain-store.ts            # Domain-wide shared store — if needed
├── models/                        # Domain-wide domain types, mappers, constants
│   ├── index.ts
│   ├── my-domain-models.ts
│   └── my-domain-mapper.ts
├── components/                    # Shared within this domain
│   └── domain-header/
│       ├── domain-header.ts
│       ├── domain-header.html
│       └── domain-header.scss
└── pages/                         # Routable entry points
    ├── page-a/
    └── page-b/
```

The `pages/` vs `components/` distinction exists **only at the domain root**. Inside a page or component, children always go in `components/`.

### Domain-Root Store vs Component State

Two kinds of signal-based containers coexist:

| Container | Location | Scope | When to use |
|-----------|----------|-------|-------------|
| **Domain store** | `domain/{domain}/{domain}-store.ts` | Singleton (`providedIn: 'root'`) — shared across components and potentially across domains | State that must be consistent across multiple components (list data, polling, cross-component filters), or reused by another domain |
| **Component state** | `{component}/{component}-state.ts` | Per-component (provided on the component) | State local to one component subtree — form state, UI-only toggles, component-scoped async |

The domain store/state injects the matching `core/services/api/<domain>/<domain>-api.ts` and is the **only** place where API observables are `subscribe()`d for display data. DTO → domain-model mapping happens inside the store/state, using a mapper from the domain-root or component-root `models/` folder. See `dto-mapper-models.md`.

---

## Canonical Component Structure (Fractal)

Every component — whether a page, a domain-shared component, or a deeply nested child — follows the same structure. The pattern repeats at every level with no depth limit.

```
my-component/
├── my-component.ts                # Component (presentation)
├── my-component.html              # Template
├── my-component.scss              # Styles
├── my-component-state.ts          # State service — if needed
├── my-component-utils.ts          # Utility functions — if needed
├── my-component.routes.ts         # Route definition — if routable
├── models/                        # Domain layer — if needed
│   ├── index.ts                   # Barrel export
│   ├── my-component-models.ts     # Domain types/interfaces
│   ├── my-component-mapper.ts     # DTO → domain model mapping
│   └── my-component.constants.ts  # Component-scoped constants
└── components/                    # ALL child components — always
    ├── simple-child/
    │   ├── simple-child.ts
    │   ├── simple-child.html
    │   └── simple-child.scss
    └── complex-child/
        ├── complex-child.ts
        ├── complex-child.html
        ├── complex-child.scss
        ├── complex-child-state.ts
        ├── models/
        │   ├── index.ts
        │   ├── complex-child-models.ts
        │   └── complex-child-mapper.ts
        └── components/
            └── grandchild/
                ├── grandchild.ts
                ├── grandchild.html
                └── grandchild.scss
```

---

## File Naming: No Redundant Suffixes

Do not use `.component` or `.service` suffixes in file names:

```
✅ Good:
my-component.ts
my-component-state.ts
my-component-utils.ts

❌ Bad:
my-component.component.ts
my-component-state.service.ts
```

### Naming Table

| Type | Location | Naming |
|------|----------|--------|
| Component | component root | `{component}.ts` |
| Template | component root | `{component}.html` |
| Styles | component root | `{component}.scss` |
| State Service | component root | `{component}-state.ts` |
| Utilities | component root | `{component}-utils.ts` |
| Routes | component root | `{component}.routes.ts` |
| Domain Models | `models/` | `{component}-models.ts` |
| Mapper | `models/` | `{component}-mapper.ts` |
| Constants | `models/` | `{component}.constants.ts` |
| Pipe | component root | `{name}.pipe.ts` |

---

## `models/` Folder

The `models/` folder holds domain types, mappers, and constants for a component.

```typescript
// models/job-list-models.ts — domain types
export type Job = {
  name: string;
  status: JobStatus;
  lastRun: dayjs.Dayjs;
}

// models/job-list-mapper.ts — DTO → domain model
export const toJob = (dto: JobDto): Job => ({
  name: dto.name,
  status: dto.status ?? null,
  lastRun: parseUtcDate(dto.lastExecutionTime),
});

// models/job-list.constants.ts — component-scoped constants
export const DEFAULT_PAGE_SIZE = 25;
export const SORTABLE_COLUMNS = ['name', 'status', 'lastRun'] as const;
```

Create a `models/` folder when:
- A mapper exists (DTO → domain model conversion).
- Types are shared across 2+ files in the component.
- Constants are used across multiple files in the component.

---

## Constants Placement

| Scope | Location |
|-------|----------|
| Single-use (one file only) | Inline in the file that uses it |
| Component-scoped (across files in one component) | `models/{name}.constants.ts` |
| Domain-wide (across components in a domain) | `models/{name}.constants.ts` at the domain root level |

---

## Sibling-Shared Utilities (`{component}-utils.ts`)

Pure helpers and constants used by more than one component in the same subtree live in `{component}-utils.ts` at the **nearest common ancestor's** component root. Each consumer imports from it via a relative path. Do not hoist to `core/utils/` until there is at least one consumer outside that subtree.

```
metrics-section/
├── metrics-section.ts               # imports { TB_THRESHOLD, formatGigaBytes }
├── metrics-section-utils.ts         # exports TB_THRESHOLD, formatGigaBytes
└── components/
    └── metric-card/
        └── metric-card.ts           # imports { formatGigaBytes }
```

### Decision tree

| Used by | Placement |
|---------|-----------|
| One file only | Module-level `const` arrow below the class in that file |
| Two or more files within a component subtree | `{component}-utils.ts` at the nearest common ancestor's root |
| Multiple unrelated domains | `core/utils/<topic>.ts` |

### Example

```typescript
// metrics-section/metrics-section-utils.ts
export const TB_THRESHOLD = 1024;

export const formatGigaBytes = (gb: number): string =>
    gb >= TB_THRESHOLD ? `${(gb / TB_THRESHOLD).toFixed(1)} TB` : `${gb} GB`;
```

Helpers scoped to a single file stay below the class as pure `const` arrows. See [component.md](component.md) — *Pure helper placement*.

---

## `components/` Subdirectory

**All child components go in a `components/` folder. Always.** No child component folders at the component root. This keeps the root clean regardless of how many children exist.

```
✅ Good:
my-component/
├── my-component.ts
├── my-component-state.ts
└── components/
    ├── child-a/
    ├── child-b/
    └── child-c/

❌ Bad:
my-component/
├── my-component.ts
├── my-component-state.ts
├── child-a/
├── child-b/
└── child-c/
```

---

## When a State Service Is Needed

A component needs a state service (`*-state.ts`) if it has:
- Internal state that changes over time.
- User interactions/events to react to.
- API calls or async operations.
- Business logic beyond simple data transformation.

```typescript
// ✅ Has logic and events → state service
@Component({ providers: [JobListState] })
export class JobListComponent {
  readonly state = inject(JobListState);
}

// ✅ Purely presentational → no state service
@Component({ ... })
export class UserAvatarComponent {
  user = input.required<User>();
  size = input<'sm' | 'md' | 'lg'>('md');
}
```

---

## Barrel Exports (`index.ts`)

Every folder whose contents are imported by other folders should have an `index.ts`:

```typescript
// models/index.ts
export { Job, JobStatus } from './job-list-models';
export { toJob } from './job-list-mapper';
export { DEFAULT_PAGE_SIZE } from './job-list.constants';
```

**Has barrel:** `models/`, shared component folders — any folder with external consumers.

**No barrel:** Domain component folders, simple child component folders — they're not imported by path, they're routed to or declared.

---

## Reusable Components

Components start where they're first needed. The moment a component is needed in a second domain, move it to `shared/components/`.

```
shared/components/
├── date-time-picker/
├── pagination/
└── confirm-dialog/
```
---

## Before Adding Complexity

1. **Is this used more than once?** If no, don't abstract it.
2. **Does this solve a current problem?** If no, don't add it.
3. **Can I delete this without breaking anything?** If yes, delete it.
4. **Would a junior dev understand this easily?** If no, simplify it.

### Signs of Overengineering

- Multiple services for one tightly-coupled component.
- Separate files for 1-5 line types.
- Abstract base classes with one implementation.
- `ngDoCheck` for state sync (use signals).
- Manual DOM manipulation (use Angular bindings).
- Dead code (files that aren't imported).
