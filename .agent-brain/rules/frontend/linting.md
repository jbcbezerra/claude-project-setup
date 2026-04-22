# Linting & Formatting

ESLint is the linter; Prettier handles formatting. Both run from the frontend project root.

---

## Tooling

- **Linter:** ESLint flat config (`eslint.config.js`) via `angular-eslint` + `typescript-eslint`, invoked through the Angular CLI (`@angular-eslint/builder:lint`).
- **Formatter:** Prettier (`.prettierrc.json`).
- **Compat:** `eslint-config-prettier/flat` is the **last** entry of both the `*.ts` and `*.html` config blocks so ESLint never fights Prettier over stylistic rules.

## Commands

Run from the frontend project root:

| Command | What it does |
|---------|--------------|
| `npm run lint` | Lint `src/**/*.{ts,html}` via `ng lint`. No formatting. |
| `npm run lint:fix` | Same as above + apply auto-fixes where ESLint can. |
| `npm run format` | Prettier-write `src/**/*.{ts,html,css,json}`. |
| `npm run format:check` | Prettier-check only (CI-style). |

The verification loop order is **format → lint → test → build**.

## What ESLint enforces

From the flat config:

- `@eslint/js` recommended.
- `typescript-eslint` `recommended` + `stylistic`.
- `angular-eslint` `tsRecommended` (TS rules) for `*.ts`.
- `angular-eslint` `templateRecommended` + `templateAccessibility` for `*.html`.
- Component selector: `<prefix>-<kebab-case>` (element) — the project's configured selector prefix (default `app`).
- Directive selector: `<prefix><camelCase>` (attribute).

Template a11y is on: `label-has-associated-control`, `click-events-have-key-events`, `interactive-supports-focus`, etc. Any `<label>` needs an `id`/`for` pair, and any `(click)` on a non-button element needs a matching keyboard handler + `role` + `tabindex`.

## Allowed exceptions (per-declaration `eslint-disable-next-line`)

These are the only cases where a disable comment is acceptable. Anything else requires a proper fix.

### Attribute-selector components for DOM-native tags

Components whose selector is `th[app-xxx]`, `tr[app-xxx]`, `li[app-xxx]`, etc. violate `@angular-eslint/component-selector`'s `type: 'element'`. They are allowed only when the DOM must stay native — typically tables (`<th>` must be a direct child of `<tr>`) or lists. Add a single-line disable above the `selector`:

```typescript
@Component({
    // eslint-disable-next-line @angular-eslint/component-selector
    selector: 'th[app-sortable-th]',
    // ...
})
```

Why: element-selector components wrapped around a `<th>` would produce invalid DOM (`<app-sortable-th>` as a child of `<tr>`). Attribute selectors let us extract the header chrome while keeping the native table structure.

## Anti-patterns

- **Do not** add `eslint-plugin-prettier`. It runs Prettier as a lint rule — slow and noisy. Use the standalone `format` / `format:check` scripts.
- **Do not** disable rules wholesale to silence first-run errors. If a rule is genuinely wrong for the codebase, disable it explicitly in `eslint.config.js` with a one-line comment explaining why.
- **Do not** name outputs after DOM events (`click`, `copy`, `close`, `search`, `focus`, `blur`, etc.) — `@angular-eslint/no-output-native` bans them, and the native event double-fires alongside the component output, forcing a `stopPropagation` workaround inside the component. See [output-naming.md](output-naming.md).
- **Do not** run `prettier` as part of `lint` — they are separate steps in the verification loop.
