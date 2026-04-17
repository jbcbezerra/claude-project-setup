# ViewEncapsulation.None Audit

## Context

52 components use `ViewEncapsulation.None`, which disables Angular's style scoping and makes component styles global. This is often a legacy pattern from AngularJS migration where components needed to override third-party styles or share styles across components. It leads to style conflicts, makes refactoring risky, and defeats component isolation.

---

## Approach

### Step 1: Categorize Each Usage

For each of the 52 components, determine why `ViewEncapsulation.None` was used:

**Category A — Overriding third-party component styles** (Material, PrimeNG, Highcharts, JointJS, ACE Editor)
- Fix: Use `::ng-deep` with component-scoped styles, or use the library's theming API
- PrimeNG: use `styleClass` prop or CSS custom properties
- Highcharts/JointJS: styles may legitimately need to be global

**Category B — Sharing styles between parent and child components**
- Fix: Move shared styles to `src/styles/` global stylesheets, then use default encapsulation in the component

**Category C — No apparent reason / copy-paste from template**
- Fix: Simply remove `encapsulation: ViewEncapsulation.None` — default encapsulation should work

**Category D — Legitimately needs global styles** (e.g., dynamically injected HTML)
- Keep `ViewEncapsulation.None` but document why

### Step 2: Migrate Per Category

1. **Category C first** — remove `encapsulation: ViewEncapsulation.None`, rebuild, check visual appearance
2. **Category B** — extract shared styles to global scss files, then remove `None`
3. **Category A** — use `::ng-deep` or library theming APIs
4. **Category D** — keep and document

---

## Key Files (52 components)

Major areas:
- `src/app/administration/` — deployment, LDAP, various admin panels
- `src/app/error-list/` — error display components
- `src/app/trees-viewer/` — process visualization
- `src/app/argos/` — dashboard components
- `src/app/shared/components/` — shared UI components

---

## Risk

This is a visual change — each component must be visually verified after removing `ViewEncapsulation.None`. Styles that were accidentally global may break when scoped.

---

## Verification

Per component:
1. Remove `encapsulation: ViewEncapsulation.None`
2. `ng build` — compiles
3. Visual comparison in browser — component looks the same
4. Check that no other components lost their styling (global styles may have been relied upon)
