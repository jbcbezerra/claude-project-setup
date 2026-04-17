# Introduce TailwindCSS + Create Button Component with Cypress CT

## Context

The project is migrating away from PrimeNG/Material UI toward custom Tailwind-based components. This plan introduces TailwindCSS to the Angular 17 project and creates the first reusable button component (`nj-button`) as a foundation. The button consolidates styles from `_pbutton.scss` (PrimeNG overrides) and `_buttons.scss` (custom buttons) into a single standalone component. Cypress component tests validate the button in isolation.

---

## Step 1: Install TailwindCSS v3

```bash
npm install -D tailwindcss@3 postcss autoprefixer
```

**Why v3**: Mature PostCSS plugin pipeline, works with `@angular-builders/custom-webpack`. The `prefix` option is critical to avoid PrimeFlex class collisions.

---

## Step 2: Create `tailwind.config.js` (project root)

- **`prefix: 'tw-'`** — avoids collisions with PrimeFlex (`flex`, `p-*`, `w-*`, etc.)
- **`preflight: false`** — don't reset existing PrimeNG/global styles
- **`content: ['./src/**/*.{html,ts}']`** — JIT scans templates
- **Theme colors** mirrored from `src/styles/abstracts/_colors.scss`:
  - `im-secondary: #616cf7`
  - `im-red: #d40714`
  - `im-green: #3fc400`
  - `im-error: #d40714`
  - `im-surface-2-light: #efefef`
  - `im-surface-4: #c7c7c7`
  - Full palette from `_colors.scss`

---

## Step 3: Create `postcss.config.js` (project root)

```js
module.exports = {
  plugins: { tailwindcss: {}, autoprefixer: {} },
};
```

Angular's internal SCSS pipeline auto-discovers this. No changes needed to `webpack.config.js`.

---

## Step 4: Add Tailwind directives to `src/styles.scss`

Add at the **top** of the file, before all other imports:

```scss
@tailwind base;
@tailwind components;
@tailwind utilities;
```

---

## Step 5: Create button component

**Directory**: `src/app/shared/components/buttons/`

**Files**:
- `nj-button.component.ts` — standalone, signals API (`input()`, `output()`, `computed()`)
- `nj-button.component.html` — uses Tailwind utilities (with `tw-` prefix) for structural layout, `ngClass` for variant/size classes
- `nj-button.component.scss` — variant/size/state styles using SCSS color variables

### Component API

| Input | Type | Default | Description |
|-------|------|---------|-------------|
| `variant` | `'primary' \| 'secondary' \| 'danger' \| 'text' \| 'green' \| 'black' \| 'bordered'` | `'secondary'` | Visual style |
| `size` | `'default' \| 'small' \| 'inline'` | `'default'` | Size preset |
| `disabled` | `boolean` | `false` | Disabled state |
| `iconOnly` | `boolean` | `false` | Icon-only mode (2rem × 2rem) |
| `type` | `'button' \| 'submit' \| 'reset'` | `'button'` | HTML button type |

**Output**: `clicked` — emits `MouseEvent` (suppressed when disabled)

### Variant styles (from existing SCSS)

| Variant | Background | Text | Hover | Source |
|---------|-----------|------|-------|--------|
| `primary` | `$im-secondary` (#616cf7) | white | darken 10% | `_buttons.scss` `.primary` |
| `secondary` | `$im-surface-2-light` (#efefef) | black | text → `$im-secondary` | `_buttons.scss` default + `_pbutton.scss` `.p-button-secondary` |
| `danger` | `$im-error` (#d40714) | white | — | `_pbutton.scss` `.p-button-danger` |
| `text` | transparent | inherit | bg → `$im-surface-2-light` | `_pbutton.scss` `.p-button-text` |
| `green` | `$im-green` (#3fc400) | white | — | `_buttons.scss` `.green` |
| `black` | black | white | — | `_buttons.scss` `.black` |
| `bordered` | white | inherit | text → `$im-secondary` | `_buttons.scss` `.bordered` |

### Size styles

| Size | Height | Padding | Border-radius |
|------|--------|---------|---------------|
| `default` | 32px min | `0 9px` | `0.75rem` |
| `small` | 1.5rem | `0.5rem` | `0.75rem` |
| `inline` | 14px | `0 3px` | `2px` |

---

## Step 6: Set Up Cypress Component Testing

**Install**: Cypress Angular CT adapter

```bash
npm install -D @cypress/angular
```

**Update `cypress.config.ts`** — add `component` block:

```ts
component: {
  devServer: { framework: 'angular', bundler: 'webpack' },
  specPattern: 'src/**/*.cy.ts',
  supportFile: 'cypress/support/component.ts',
  indexHtmlFile: 'cypress/support/component-index.html',
}
```

**Create support files**:
- `cypress/support/component.ts` — register `mount` command from `cypress/angular`
- `cypress/support/component-index.html` — minimal HTML shell with `<div data-cy-root>`

**Update `cypress/tsconfig.json`** — include `../src/**/*.cy.ts`

**Add npm scripts**:
```json
"cy:component": "cypress open --component",
"cy:component:run": "cypress run --component"
```

---

## Step 7: Write Component Tests

**File**: `src/app/shared/components/buttons/nj-button.component.cy.ts`

### Test cases

1. Renders with default (secondary) variant
2. Renders primary variant with correct background color (`rgb(97, 108, 247)`)
3. Renders danger variant with correct background color (`rgb(212, 7, 20)`)
4. Applies disabled state (opacity 0.7, not clickable)
5. Does not emit click when disabled
6. Emits click when enabled
7. Applies small size class
8. Applies icon-only mode class
9. Renders projected content (`<ng-content>`)
10. Sets correct button type attribute

---

## Verification

1. `npm run build` — no build errors, no regressions
2. `npx cypress open --component` — all 10 button tests pass
3. Visual check — existing pages unaffected (PrimeFlex/PrimeNG styles intact)

---

## Key Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| PrimeFlex class collisions | Broken layouts across entire app | `prefix: 'tw-'` eliminates this |
| Preflight resets PrimeNG themes | Visual regression on all PrimeNG components | `corePlugins: { preflight: false }` |
| SCSS color variables drift from Tailwind config | Inconsistent colors | Cross-reference comments in both `_colors.scss` and `tailwind.config.js` |
| Cypress CT Angular compatibility on Node 24 | CT won't boot | Test early; pin cypress version if needed |
| Bundle size increase | Exceeds budget | Tailwind v3 JIT only emits used classes; minimal increase |

---

## Critical Files

- `src/styles/abstracts/_colors.scss` — color source of truth
- `src/styles.scss` — add Tailwind directives
- `src/styles/vendor/primeng/_pbutton.scss` — existing PrimeNG button overrides (reference)
- `src/styles/component/_buttons.scss` — existing custom button styles (reference)
- `webpack.config.js` — verify no PostCSS conflicts (no changes expected)
- `cypress.config.ts` — add component testing configuration
- `angular.json` — verify style preprocessor options
