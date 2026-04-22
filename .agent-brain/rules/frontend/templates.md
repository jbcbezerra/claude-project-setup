# Template Rules

All rules for Angular component `.html` templates.

---

## Control Flow

Use Angular's built-in control flow syntax. Structural directives are banned.

| Legacy (banned) | Modern (required) |
|---|---|
| `*ngIf="cond"` | `@if (cond) { ... }` |
| `*ngIf="cond; else elseRef"` | `@if (cond) { ... } @else { ... }` |
| `*ngFor="let x of xs"` | `@for (x of xs; track ...) { ... }` |
| `*ngSwitch` / `*ngSwitchCase` | `@switch (expr) { @case (val) { ... } }` |

### @for track expressions

Every `@for` block **must** include a meaningful `track` expression:

- `track item.id` (or another unique field) when iterating objects with identity.
- `track kv.key` when iterating `| keyvalue` pipe output.
- `track $index` **only** for primitive arrays or when items genuinely lack a unique identifier.
- Never leave the schematic default `track item` without reviewing it.

### CommonModule cleanup

After migrating to built-in control flow, remove standalone `NgIf`, `NgFor`, `NgSwitch` imports. Replace `CommonModule` with only the specific directives/pipes still in use (`NgClass`, `NgStyle`, `KeyValuePipe`, `DatePipe`, `DecimalPipe`, `AsyncPipe`, etc.). Remove `CommonModule` entirely if no Common features remain.

---

## Display Bindings — No Method Calls

Display bindings (`{{ … }}`, `[attr]="…"`, `[class]="…"`, `[style.x]="…"`, `@if`/`@for` conditions) must read **signals or plain properties only**. Never call methods in these positions — they re-run every change-detection tick.

Event bindings (`(click)`, `(change)`, …) **must** be method calls. This rule does not apply there.

### Allowed

```html
{{ state.tree()[key].iconClass }}          <!-- signal read + property access -->
{{ row.left }}                              <!-- plain property -->
[class.active]="isEnabled()"                <!-- signal read -->
@if (state.tree()[key].error; as err) { }   <!-- signal read + property -->
```

### Banned

```html
<i [class]="getIconClass(state)"></i>
@if (featureStatusService.isFeatureEnabled('arg')) { }
{{ computeDisplayName(row) }}
@for (c of buildConnectors(); track c.id) { }
```

### How to fix

| Was | Becomes |
|-----|---------|
| `getIconClass(state)` in template | Mapper builds `view.iconClass` → bind `view.iconClass` |
| `service.isFeatureEnabled('x')` | `isXEnabled = service.isFeatureEnabledSignal('x')` → bind `isXEnabled()` |
| `formatDate(row.createdAt)` | Pure pipe or precomputed property on the row view |
| `buildList()` inside `@for` | `readonly list = LIST_CONFIG` class property |

---

## Class & Style Bindings

Use native Angular `[class]` and `[style]` bindings. Never use `NgClass` or `NgStyle` directives.

### Single conditional class
```html
<div [class.active]="isActive">
<div [class.hide-blocker]="!loading">
```

### Multiple conditional classes — split into individual bindings
```html
<button [class.active]="isSelected" [class.disabled]="!canSelect">
```

### Dynamic class string (expression, method, or pipe)
```html
<span [class]="'prefix-' + state">
<i [class]="iconClass()">
<span [class]="status | statusPipe">
```

### [class] overwrites static classes
When an element has a static `class` attribute, **do not** use `[class]="expr"` — it replaces all static classes. Instead:
- **Preferred:** use individual `[class.x]="cond"` bindings alongside `class="static"`.
- **If needed:** merge static into expression: `[class]="'static-a static-b ' + dynamicExpr"`.

### Multi-class conditional key
```html
<!-- WRONG: ngClass allowed space-separated keys -->
[ngClass]="{ 'class-a class-b': condition }"

<!-- CORRECT: split into individual bindings -->
[class.class-a]="condition" [class.class-b]="condition"
```

### Tailwind arbitrary-value classes — use object-map form

Class names containing brackets (Tailwind arbitrary values like `text-[0.65rem]`, `w-[2.5rem]`, `bg-[#1a1a1a]`) cannot use `[class.x]="cond"` attribute-key syntax — Angular's template parser treats the inner `]` as the attribute-key terminator and drops everything after it.

Use Angular's native object-map class binding instead. It is a first-class Angular feature — not the banned `NgClass` directive — and coexists with static `class="..."` and with other `[class.x]` bindings on the same element.

```html
<!-- ❌ WRONG: inner ] terminates the attribute, produces truncated class -->
<span [class.text-[0.65rem]]="isSmall()">

<!-- ❌ WRONG: NgClass directive is banned -->
<span [ngClass]="{ 'text-[0.65rem]': isSmall() }">

<!-- ✅ CORRECT: native [class] object-map binding (not NgClass) -->
<span
  class="font-mono text-text-dark"
  [class.uppercase]="isUppercase()"
  [class]="{ 'text-[0.65rem]': isSmall() }">
```

When an element has both `[class]` and `[class.x]` bindings plus a static `class="..."`, Angular merges all three.

### Style bindings

```html
<!-- Static — plain HTML -->
<th style="display: none">

<!-- Dynamic with unit suffix -->
<div [style.width.%]="value">
<div [style.font-size.rem]="size">

<!-- Dynamic without unit -->
<span [style.color]="statusColor">
<div [style.visibility]="isVisible ? '' : 'hidden'">

<!-- Multiple — individual bindings -->
<div [style.top.px]="y" [style.left.px]="x">
```

### Import rules

- Never import `NgClass` or `NgStyle` from `@angular/common`.
- If `CommonModule` was only used for `NgClass`/`NgStyle`, replace with specific imports or remove entirely.

---

## Host Bindings & Styling

Apply dynamic classes and styles on the host element via the `host` property in `@Component`, not `@HostBinding`:

```typescript
@Component({
  host: {
    '[class.active]': 'isActive()',
    '[class.disabled]': 'disabled()',
    '[style.display]': 'hidden() ? "none" : null',
  },
})
```

Style `:host` in SCSS — no wrapper `<div>`:

```scss
:host {
  display: flex;
  flex-direction: column;
  gap: 1rem;

  &.disabled {
    opacity: 0.6;
    pointer-events: none;
  }
}
```

```html
<!-- ✅ No wrapper — content is the component -->
<div class="header">Header</div>
<div class="content">Content</div>

<!-- ❌ Unnecessary wrapper div -->
<div class="my-component-wrapper">
  <div class="header">Header</div>
</div>
```

---

## Self-Closing Tags

Use self-closing tags (`/>`) **only** for:

1. **Angular components** without body content.
2. **Void HTML elements** (`<br>`, `<input>`, `<img>`, `<hr>`, etc.).

Standard HTML elements must always use explicit closing tags.

```html
<!-- ✅ Angular components -->
<app-date-time-picker [value]="dateTime" />
<app-spinner />

<!-- ✅ Void HTML elements -->
<input type="text" />
<br />

<!-- ✅ Standard HTML — closing tag required -->
<i class="fa fa-check"></i>
<div class="container"></div>

<!-- ❌ Standard HTML cannot be self-closed -->
<i class="fa fa-check" />
```

---

## Section Comments

Add short HTML comments as **section labels** so developers can scan a template and jump to the right spot. Comments describe *what* the block is, not *how* it works.

### What to comment

| Scope | Example |
|-------|---------|
| Top-level layout sections | `<!-- table caption -->`, `<!-- table -->` |
| Logical groups inside a section | `<!-- title & refresh btn -->`, `<!-- table actions -->` |
| Repeated structural items (columns, cells) | `<!-- username -->`, `<!-- checkbox -->` |
| Named template slots / ng-templates | `<!-- header -->`, `<!-- body -->`, `<!-- empty -->` |

### What NOT to comment

- Every single HTML tag — only comment **meaningful boundaries**.
- Implementation details (`<!-- calls the API -->`) — those belong in the TS file.
- Closing-tag comments (`<!-- /div -->`).

### Style

- Lowercase, short noun phrase (2-4 words).
- Place the comment on the line directly above the element it labels.
- Use `&` for compound labels: `<!-- title & refresh btn -->`.

### Example

```html
<div class="content-container">
    <!-- table caption -->
    <div class="row-centered-vertical justify-content-between">
        <!-- title & refresh btn -->
        <div class="row-centered-vertical">
            <h2>Sessions</h2>
            ...
        </div>
        <!-- table actions -->
        <div class="row-centered-vertical gap-2">...</div>
    </div>

    <!-- table -->
    <table cdk-table>
        <!-- header -->
        ...
        <!-- body -->
        ...
        <!-- empty -->
        ...
    </table>
</div>
```

### Anti-patterns

```html
<!-- BAD: commenting every tag -->
<!-- outer div -->
<div>
    <!-- inner div -->
    <div>
        <!-- span -->
        <span>text</span>
    </div>
</div>

<!-- BAD: implementation comment -->
<!-- fetches sessions from the API and refreshes the table -->
<button (click)="onLoadSessions()">Refresh</button>

<!-- BAD: long verbose -->
<!-- This section contains the action buttons for killing sessions -->
<div class="row-centered-vertical gap-2">...</div>

<!-- GOOD: short label -->
<!-- table actions -->
<div class="row-centered-vertical gap-2">...</div>
```
