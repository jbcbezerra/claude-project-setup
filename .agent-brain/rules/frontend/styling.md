# Styling Rules

All rules for component and template styling (Tailwind utilities, SCSS, units).

> This ruleset assumes Tailwind CSS 4 with CSS-first theming (`@theme { ... }` in `src/styles.css`). If your project uses Tailwind 3 with `tailwind.config.js`, the principles still apply — translate token declarations from `@theme` to `theme.extend` in the config.

---

## Styling Framework: Tailwind

Use **Tailwind CSS 4** (`@import 'tailwindcss';` in `src/styles.css`).

Theme tokens (colors, fonts, radius, etc.) are defined in `src/styles.css` via CSS custom properties under `:root` / `:root.dark`, and exposed to Tailwind through the `@theme` block. Dark mode is handled with the custom variant `dark (&:where(.dark, .dark *))`.

---

## Utility-First Priority

When styling a component, follow this order — stop at the first level that can express the style cleanly:

1. **Tailwind utility classes** in the template — first choice.
2. **Theme tokens via Tailwind** (`bg-surface`, `text-text-muted`, `border-border-light`, etc.) — first choice for anything color/spacing/typography-related.
3. **Component `.scss`** with `:host`, pseudo-elements, or state selectors — last resort.

### Prefer theme tokens over raw values

Colors, radii, and other design tokens are defined once in `src/styles.css` (`@theme { --color-primary: …; }`). Use the corresponding Tailwind utility (`bg-primary`, `text-primary`, `border-border-light`) instead of hard-coded hexes or `bg-[#135bec]`. This keeps dark-mode and theme switches working without touching individual components.

```html
<!-- ✅ Theme token -->
<div class="bg-surface text-text-dark border border-border-light">

<!-- ❌ Hard-coded — bypasses dark mode and future re-themes -->
<div class="bg-[#ffffff] text-[#1a202c] border border-[#e2e8f0]">
```

### Dark mode

Use Tailwind's `dark:` variant for dark-mode-specific utilities:

```html
<div class="bg-surface dark:bg-surface-dark text-text-dark">
```

Prefer defining a new CSS var on `:root.dark` and using a single token, rather than pairing `light:` / `dark:` utilities for every color. Reach for `dark:` utilities only when a specific element needs a value that differs from the token.

### Adding new tokens

If a color, spacing value, or radius is reused across more than one place, add it to `src/styles.css`:

1. Declare it on `:root` (and `:root.dark` if it has a dark variant) as a CSS variable.
2. Re-export it under `@theme { … }` so Tailwind generates the utility class.
3. Use the Tailwind utility everywhere — do not re-declare the raw value per-component.

### Component `host:` property in TypeScript

The `host:` metadata in `@Component` should only contain:

1. **Tailwind utility classes** — via `class:` (e.g. `'inline-flex items-center justify-center rounded-full'`).
2. **Dynamic style bindings** driven by inputs or computed signals (e.g. `'[style.width]': 'size()'`).

Static style declarations that don't depend on inputs belong in the component's `.scss` file under `:host`, not as inline `[style.*]` bindings in the TS.

```typescript
/* CORRECT — Tailwind classes + input-driven bindings */
host: {
    class: 'inline-flex items-center justify-center rounded-full',
    '[style.width]': 'circleSize()',
    '[style.color]': 'iconColor()',
}

/* WRONG — static styles that should be in SCSS */
host: {
    '[style.border-style]': '"solid"',
    '[style.border-width]': '"0.08rem"',
}
```

### Component `.scss` — when it's the right choice

Writing styles directly in the component's stylesheet is correct for:

- **`:host` and `:host-context(...)`** — scoping rules that can't be expressed as classes.
- **`::ng-deep` / pseudo-elements** (`::before`, `::after`, `::placeholder`) — Tailwind can't target these.
- **Descendant/state selectors** that depend on component internals — `.tab:hover .icon`, `[data-state='error'] input`, third-party library overrides.
- **Animations / keyframes / transitions** with component-specific timing.
- **Truly one-off values** that would never be reused.
- **CSS variables or calc()** tied to runtime inputs.

Inside `.scss`, read theme tokens via `var(--color-…)` rather than duplicating values.

### Before adding styles

1. Check if a Tailwind utility already expresses what you need — it probably does.
2. If you'd reach for an arbitrary value (`w-[3.38rem]`, `bg-[#123]`), check whether it should become a theme token in `src/styles.css` instead.
3. Otherwise (pseudo-elements, `:host`, animations, component-specific selectors) → component `.scss`.

---

## Rem Over Px

Prefer `rem` over `px` for any custom lengths you write yourself in component SCSS or Tailwind arbitrary values (`w-[2rem]`, not `w-[26px]`). Use `px` only when a feature genuinely needs pixel-exact output (hairline borders on non-HiDPI targets, raster image sizing, etc.) — and call it out with a comment.

Tailwind's default spacing scale (`p-1`, `w-8`, etc.) already emits rem values — sticking to the scale is the preferred path.

### Applies to

Every numeric value with a length unit you write in component `.scss` (or inside Tailwind `[...]` arbitrary values):

- `width`, `height`, `min-width`, `max-width`, etc.
- `padding`, `margin`, `gap`.
- `top`, `right`, `bottom`, `left`.
- `border-width`, `border-radius`.
- `line-height` (when given as a length, not a unitless multiplier).
- `transform: translate*()` offsets.

Negative values follow the same rule (e.g. `left: -11px` → convert to the corresponding negative rem).

### Exceptions

- **`calc(100% - Npx)`** — convert the subtracted length too.
- **`box-shadow`, `text-shadow`** — blur/spread values in px are acceptable; convert offsets if layout-significant.
- **Unitless `line-height`** (e.g. `line-height: 1.4`) — leave as-is.
- **`0`** has no unit and never needs conversion.

### Anti-patterns

```scss
/* BAD: px scattered through a component */
:host {
  height: 55px;
  padding: 0 15px;
  border-radius: 10px;
}

/* GOOD: rem-based (or better: use Tailwind utilities in the template instead) */
:host {
  height: 3.5rem;
  padding: 0 1rem;
  border-radius: 0.5rem;
}
```

```html
<!-- BAD: arbitrary px -->
<div class="w-[200px] p-[15px] rounded-[10px]">

<!-- GOOD: scale utilities (rem-based) -->
<div class="w-52 p-4 rounded-lg">
```

---

## Why Rem

Rem values scale with the user's browser font-size setting, honor accessibility zoom, and keep spacing proportional across components. Hard-coded px lock the layout to one font-size. Tailwind's default scale is already rem-based; staying on the scale means any project-wide typography change propagates everywhere without touching individual components.
