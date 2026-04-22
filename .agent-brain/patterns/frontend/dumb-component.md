# Dumb (Presentational) Component

Use this skeleton for any leaf or mid-tree Angular component whose entire job is to render inputs — no async work, no routing, no services beyond `BaseComponent`'s logger.

> **Constraints live in [rules/frontend/component.md](../../rules/frontend/component.md), [rules/frontend/templates.md](../../rules/frontend/templates.md), and [rules/frontend/styling.md](../../rules/frontend/styling.md)**. This file shows the canonical shape; the rules explain **why**.
>
> For a component that injects services or owns a subscription lifecycle, use the general [component pattern](component.md) instead (when present).

---

## Skeleton

```typescript
import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';
import { BaseComponent } from '<relative-path>/base-component';

@Component({
	selector: 'app-<name>',
	templateUrl: './<name>.html',
	styleUrl: './<name>.scss',                    // keep the file even if empty — template references it
	changeDetection: ChangeDetectionStrategy.OnPush,
	host: {
		class: '<tailwind layout + static look classes>',
		'[class.<state>]': '<stateSignal>()',     // conditional classes on the host — never a wrapper div
	},
	imports: [<only the child components this template renders>],
})
export class <Name>Component extends BaseComponent {
	readonly <input> = input.required<<T>>();
	readonly <optional> = input<<T>>(<default>);

	protected readonly <derived> = computed(() => /* pure derivation from inputs */);
}

// Pure, no `this`. Lives below the class OR in <component>-utils.ts when shared with siblings.
const <helper> = (/* args */) => /* result */;
```

Template shape:

```html
<!-- section label if the template has multiple regions -->
<span data-cy="<role>" [class]="'<static classes> ' + <computedClasses>()">{{ label() }}</span>
<app-<child> [input]="value()" class="flex-1" />
```

SCSS:

```scss
/* Empty. Tailwind + host: { class } covers it. Add :host / pseudo-elements only if truly needed. */
```

## When to use

- A component that reads inputs, derives display-only state with `computed()`, and renders children in its template.
- No services injected beyond what `BaseComponent` already provides.
- No subscriptions, no timers, no effects, no outputs that aren't plain `output<T>()` for an event.

If any of those don't hold, use the general component skeleton instead of this one.

## Quick checklist

1. `changeDetection: ChangeDetectionStrategy.OnPush` — always.
2. All inputs declared via `input()` / `input.required<T>()`. No `@Input()`.
3. Static layout / look classes live on `host.class`. **No wrapper `<div>`** at the top of the template.
4. Conditional classes use `'[class.<x>]': '<flag>()'` on the host, or `[class.<x>]="<flag>()"` on a child element. Never `ngClass` / `ngStyle`.
5. Every derived value is a `computed()` — no getters, no methods called from the template.
6. `.scss` stays empty when Tailwind covers the styling — do not delete the file, `styleUrl` references it.
7. Every selectable DOM node carries a `data-cy="<role>"` (see [testing.md](../../rules/frontend/testing.md)).
8. `imports:` lists only the child components this template renders. Never `CommonModule`.
9. Pure helpers are module-level `const <name> = (…) => …` arrows (see [file-organization.md](../../rules/frontend/file-organization.md) for the single-file-vs-sibling-shared placement rule).

## Variations

### With a conditional overlay class

Used when a single boolean flag toggles a visual state across the whole component (offline/disabled/muted). Example: `'[class.opacity-50]': 'isOffline()'` greys a card when a status flag flips.

```typescript
host: {
	class: 'bg-surface border border-border-light rounded px-2 py-1 flex flex-col',
	'[class.opacity-50]': 'isOffline()',
},
```

### With sibling-shared helpers

When two or more components in the same subtree need the same pure helper, extract it to `<ancestor>-utils.ts` at the nearest common ancestor and import via relative path.

```typescript
import { formatGigaBytes } from '../../<ancestor>-utils';

readonly ramDetails = computed(() => {
	const n = this.node();
	return `${formatGigaBytes(n.ramUsed)} / ${formatGigaBytes(n.ramMax)}`;
});
```

### With a derived class string

When a multi-class combination depends on a signal, compute the whole string and concatenate it onto the static prefix in the template.

```typescript
readonly colorClasses = computed(() =>
	this.isOffline() ? 'text-slate-300 dark:text-slate-600' : 'text-text-muted',
);
```

```html
<span [class]="'text-[0.625rem] font-mono w-6 shrink-0 ' + colorClasses()">{{ label() }}</span>
```

### With a placeholder/fallback array

For components that display a list with a known fixed length, declare a module-level placeholder constant (e.g. `ZERO_ROWS`) and return it from the display `computed()` when input data is missing and an error flag is set. Keeps the template branch-free — one `@for` over `displayRows()`.
