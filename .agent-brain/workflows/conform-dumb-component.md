# Conform Dumb Component

Bring a purely presentational Angular component into conformance with the brain's rules and patterns. Designed to be delegated to a subagent per component and fanned out in parallel.

## When to use

- Auditing or retrofitting an existing dumb (inputs-only) component against `rules/frontend/*` and `patterns/frontend/dumb-component.md`.
- Sweeping a domain after a rule change — each component becomes an independent task.
- Before extracting a component to `shared/components/` — conformance first, then move.

If the component injects services, owns subscriptions, or holds state, use the general component pattern instead; this workflow only covers dumb components.

## Inputs the subagent receives

| Field | Value |
|-------|-------|
| `componentPath` | Absolute path to the component folder (contains `<name>.ts`, `.html`, `.scss`). |

One component = one subagent. The orchestrator fans out N at a time via `superpowers:dispatching-parallel-agents`. **The component spec is part of the deliverable** — a component without a passing spec is not conformed.

## Parallel-safety rules (for the orchestrator)

- **Same subtree, shared `<ancestor>-utils.ts`:** serialize. Two agents cannot write the same utils file at once.
- **Sibling components, no shared utils:** parallelize freely.
- **Cross-domain:** always parallelizable — no overlap possible.
- Before dispatching, `grep -l "from '.*<ancestor>-utils'"` to detect shared-utils groups and batch them into a single agent instead.

## Reading list for the subagent

Pin these in the subagent's prompt — do not re-derive them from the repo:

1. `.agent-brain/patterns/frontend/dumb-component.md` — canonical skeleton.
2. `.agent-brain/rules/frontend/component.md` — DI, signals, lifecycle constraints.
3. `.agent-brain/rules/frontend/templates.md` — `@if`/`@for`, `[class]`/`[style]`, no method calls in bindings.
4. `.agent-brain/rules/frontend/styling.md` — Tailwind, `host:` metadata, `rem` over `px`.
5. `.agent-brain/rules/frontend/file-organization.md` — fractal `components/`, no `.component` suffix, `<name>-utils.ts` placement, `models/` placement.
6. `.agent-brain/rules/frontend/testing.md` — `data-cy` naming, component-spec placement.
7. Presentational-component spec skeleton (if the repo has one under `patterns/frontend/`) — cite by path. Only if the spec is missing or broken.

## Checklist (the subagent runs this in order)

### A. Classify

1. Confirm the component is dumb: no `inject()` of services beyond what `BaseComponent` provides, no `effect()`, no subscriptions, no `*-state.ts`, no outputs beyond plain `output<T>()`.
2. If **not** dumb, stop and return `{ status: "out-of-scope", reason: "…" }`. Do not convert it.

### B. Component shape (`<name>.ts`)

3. `extends BaseComponent`.
4. Standalone (no NgModule) + `changeDetection: ChangeDetectionStrategy.OnPush`.
5. All inputs via `input()` / `input.required<T>()` — no `@Input()`, no `EventEmitter`.
6. All derived values via `computed()` — no getters, no template-called methods.
7. Pure helpers are module-level `const <name> = (…) => …` arrows below the class, or in `<ancestor>-utils.ts` if used by siblings.
8. `imports:` lists only child components actually rendered in the template. No `CommonModule`. No unused entries.

### C. Template (`<name>.html`)

9. Control flow uses `@if` / `@for` / `@switch` with mandatory `track` on `@for`.
10. No `*ngIf`, no `*ngFor`, no `ngClass`, no `ngStyle`.
11. Every selectable DOM node has `data-cy="<role>"`.
12. Conditional classes use `[class.<x>]="<signal>()"` on the element or `host: { '[class.<x>]': '<signal>()' }` — never string-concatenated class attributes for boolean states.
13. No method calls in display bindings — bind the `computed()` directly.

### D. Host + SCSS (`<name>.scss`)

14. Static layout + look classes live on `host: { class: '…' }`. No wrapper `<div>` at the top of the template.
15. `.scss` stays empty when Tailwind + host covers the styling. Do not delete the file; `styleUrl` references it.
16. Any CSS in `.scss` targets `:host`, `:host(.x)`, or pseudo-elements only.

### E. File organization

17. Folder layout matches the fractal rule: child components in `components/`, siblings-shared helpers in `<ancestor>-utils.ts` at nearest common root.
18. File names use no `.component` / `.service` suffix.
19. If the component has a `models/` folder, it contains types/mappers/constants only and has an `index.ts` barrel.

### F. Component spec (mandatory)

Every conformed component ships with a passing component spec (Cypress component, or Vitest + Angular Testing Library — whichever the project uses). No skip flag — if writing the spec is blocked by a rule gap, return `blocked`, not `conformed`.

20. **Locate** the mirror path for the runner the project uses:
    - Cypress: `cypress/component/<same path as src/app/…>/<name>.cy.ts`.
    - Vitest/ATL: co-located `<name>.spec.ts`.
    Path mirrors source exactly (folder-for-folder) for the Cypress case; co-located for the Vitest case.
21. **Pick the skeleton** from `patterns/frontend/` (if one exists). Otherwise match the nearest passing spec in the codebase.
22. **Mount helper** — one per file, wraps the mount call with only the component under test in `imports:` (children are pulled in by its own `imports:` array).
23. **Required coverage** (minimum bar before the spec is accepted):
    - One `rendering` test that mounts the default state and asserts the host exists.
    - One test per `computed()` — exercise each branch (true/false, each enum value).
    - One test per conditional host class or `[class.x]` binding — assert the class is present and absent.
    - One test per named `data-cy` slot — assert the node exists and carries the expected text/attr.
    - Numeric thresholds: test **both sides of the boundary** (e.g. for `> 50`, cover `50` and `51`).
    - Object/array inputs: build with a `make<Model>(overrides: Partial<T> = {})` factory + helper from the skeleton.
24. **Selector rules**:
    - `cy.get('app-<name>')` (or testing-library equivalent) for the host.
    - `[data-cy="<role>"]` for internal nodes. Never class selectors for structural nodes.
    - Child components via their `app-<tag>` selector — assert count/position/flow-through only; do not re-test the child's internals.
25. **Assertion rules**:
    - Inline styles via `should('have.attr', 'style').and('contain', '…')` — never `have.css` (resolved to computed px, not rem/%).
    - One behavior per test. Shared setup in `beforeEach` or top of the nearest `describe`.
26. **Import style**: relative paths only. No `app/…` or `@app/…` aliases.
27. **If the component lacks `data-cy` attributes** needed for assertions, go back to step C.11 and add them to the template first — do not work around a missing selector by using classes.

### G. Verify

Run from the frontend workspace root. All four steps must pass before returning `conformed`:

```
<format cmd> <changed files>
<lint cmd> --fix <changed files>
<type-check cmd>
<component-spec cmd> <spec path>
```

The component-spec run is not optional. A green type-check with a failing spec is `blocked`, not `conformed`.

If any step fails three times, stop and return `{ status: "blocked", step: "<which>", error: "<stderr tail>" }`.

## Output the subagent returns

One JSON-shaped report per component:

```
{
  "component": "<relative path>",
  "status": "conformed" | "already-conformed" | "out-of-scope" | "blocked",
  "changed": ["<file>", …],
  "checklist": { "A.1": "ok", "B.3": "fixed", "F.20": "created", … },
  "notes": "<one-line summary of notable edits>"
}
```

Keep `notes` under 200 chars. The orchestrator aggregates these and shows the user a pass/fail table — no narrative.

## Done when

- Every dispatched agent returns `conformed`, `already-conformed`, or `out-of-scope`.
- Every `conformed` / `already-conformed` component has a spec at the mirror path that passed in step G.
- Type-check is clean for all touched files.
- `REGISTRY.md` is unchanged unless a new pattern was extracted (then run `/brain-extract`).
