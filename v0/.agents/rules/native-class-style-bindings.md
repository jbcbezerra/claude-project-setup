# Native Class & Style Bindings

Use native Angular `[class]` and `[style]` bindings. Never use `NgClass` or `NgStyle` directives.

## Class Bindings

### Single conditional class
```html
<div [class.active]="isActive">
<div [class.nj-hide-blocker]="!loading">
```

### Multiple conditional classes
Split into individual bindings:
```html
<button [class.active]="isSelected" [class.disabled]="!canSelect">
```

### Dynamic class string (from expression, method, or pipe)
```html
<span [class]="'prefix-' + state">
<i [class]="getIconClass()">
<span [class]="status | statusPipe">
```

### [class] overwrites static classes
When an element has a static `class` attribute, **do not** use `[class]="expr"` — it replaces all static classes. Instead:
- **Preferred:** use individual `[class.x]="cond"` bindings alongside `class="static"`
- **If needed:** merge static into expression: `[class]="'static-a static-b ' + dynamicExpr"`

### Multi-class conditional key
```html
<!-- WRONG: ngClass allowed space-separated keys -->
[ngClass]="{ 'class-a class-b': condition }"

<!-- CORRECT: split into individual bindings -->
[class.class-a]="condition" [class.class-b]="condition"
```

## Style Bindings

### Static values — use plain HTML
```html
<th style="display: none">
```

### Dynamic with unit suffix
```html
<div [style.width.%]="value">
<div [style.top.px]="y">
<div [style.font-size.rem]="size">
```

### Dynamic without unit
```html
<span [style.color]="statusColor">
<div [style.visibility]="isVisible ? '' : 'hidden'">
```

### Multiple style properties — individual bindings
```html
<div [style.top.px]="y" [style.left.px]="x">
```

## Import Rules

- Never import `NgClass` or `NgStyle` from `@angular/common`
- Never add `NgClass` or `NgStyle` to component/module `imports` arrays
- If `CommonModule` was only used for `NgClass`/`NgStyle`, replace with specific imports (e.g., `DecimalPipe`, `AsyncPipe`) or remove entirely
