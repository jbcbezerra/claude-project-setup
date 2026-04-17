# NgClass/NgStyle → Native Binding Migration Workflow

## Overview

Angular recommends migrating from the `NgClass` and `NgStyle` directives to native `[class]` and `[style]` bindings. This improves performance (no directive overhead), reduces bundle size (no `NgClass`/`NgStyle` imports), and aligns with modern Angular standards.

**Codebase scope:**
- **`[ngClass]`** — 309 occurrences across 115 files (+ 3 inline templates in `.ts` files)
- **`[ngStyle]`** — 39 occurrences across 14 files
- **`NgClass`/`NgStyle` imports** — ~30 TypeScript files importing from `@angular/common`

---

## Pattern Catalog & Migration Rules

### ngClass Patterns

| # | Pattern | Example (Before) | Migration (After) | Complexity |
|---|---------|-------------------|-------------------|------------|
| 1 | **Single conditional class** | `[ngClass]="{ active: isActive }"` | `[class.active]="isActive"` | Trivial |
| 2 | **Multiple conditional classes** | `[ngClass]="{ active: isActive, disabled: !enabled }"` | `[class.active]="isActive" [class.disabled]="!enabled"` | Easy |
| 3 | **String expression** | `[ngClass]="'message-processing-' + state"` | `[class]="'message-processing-' + state"` | Easy |
| 4 | **Ternary expression** | `[ngClass]="condition ? 'classA' : 'classB'"` | `[class]="condition ? 'classA' : 'classB'"` | Easy |
| 5 | **Method call returning string** | `[ngClass]="getIconClass()"` | `[class]="getIconClass()"` | Easy |
| 6 | **Method call returning object** | `[ngClass]="getClasses()"` | Convert method to return string or split into `[class.x]` bindings | Medium |
| 7 | **Array of classes** | `[ngClass]="['class1', 'class2']"` | `[class]="'class1 class2'"` (static) or keep `[class]` with joined string | Easy |

### ngStyle Patterns

| # | Pattern | Example (Before) | Migration (After) | Complexity |
|---|---------|-------------------|-------------------|------------|
| A | **Static object literal** | `[ngStyle]="{ display: 'none' }"` | `[style.display]="'none'"` or `style="display: none"` | Trivial |
| B | **Dynamic single property** | `[ngStyle]="{ width: value + '%' }"` | `[style.width.%]="value"` | Easy |
| C | **Multiple dynamic properties** | `[ngStyle]="{ top: y + 'px', left: x + 'px' }"` | `[style.top.px]="y" [style.left.px]="x"` | Easy |
| D | **Method call returning object** | `[ngStyle]="getStyles()"` | Split into individual `[style.prop]` bindings, or use `[style]` with string | Medium |
| E | **Dynamic color** | `[ngStyle]="{ color: status().color }"` | `[style.color]="status().color"` | Easy |

---

## Step-by-Step Migration (Per File)

### Step 1: Identify the Component

Pick a file to migrate. Note:
- The **template file** (`.html`) or inline `template` in the `.ts` file
- The **component/module `.ts` file** that imports `NgClass`/`NgStyle`

### Step 2: Migrate Template Bindings

Work through each `[ngClass]` and `[ngStyle]` occurrence in the template:

#### For `[ngClass]`:

**Pattern 1 — Single conditional class (most common in this codebase):**
```html
<!-- Before -->
<div [ngClass]="{ 'nj-hide-blocker': !loading }">

<!-- After -->
<div [class.nj-hide-blocker]="!loading">
```

**Pattern 2 — Multiple conditional classes:**
```html
<!-- Before -->
<button [ngClass]="{ active: isSelected('tab'), disabled: !canSelect }">

<!-- After -->
<button [class.active]="isSelected('tab')" [class.disabled]="!canSelect">
```

**Pattern 3 — String concatenation:**
```html
<!-- Before -->
<span [ngClass]="'message-processing-' + state">

<!-- After -->
<span [class]="'message-processing-' + state">
```

**Pattern 5 — Method call returning class string:**
```html
<!-- Before -->
<i [ngClass]="setMetricsComponentStateClass()">

<!-- After -->
<i [class]="setMetricsComponentStateClass()">
```
> **Note:** When using `[class]="expression"`, any static `class="..."` on the same element will be **overwritten** by the binding. Merge static classes into the expression or use individual `[class.x]` bindings to preserve them.

**Pattern 4 — Ternary:**
```html
<!-- Before -->
<i [ngClass]="shards === 0 ? 'fas fa-info' : 'fas fa-exclamation-triangle yellow'">

<!-- After -->
<i [class]="shards === 0 ? 'fas fa-info' : 'fas fa-exclamation-triangle yellow'">
```

#### For `[ngStyle]`:

**Pattern A — Static literal (24 occurrences of `{ display: 'none' }` in this codebase):**
```html
<!-- Before -->
<th [ngStyle]="{ display: 'none' }">

<!-- After — prefer plain HTML attribute for purely static values -->
<th style="display: none">
```

**Pattern B — Dynamic with unit:**
```html
<!-- Before -->
<div [ngStyle]="{ width: value + '%' }">

<!-- After — Angular supports unit suffix -->
<div [style.width.%]="value">
```

**Pattern C — Multiple dynamic properties:**
```html
<!-- Before -->
<div [ngStyle]="{ top: y + 'px', left: x + 'px' }">

<!-- After -->
<div [style.top.px]="y" [style.left.px]="x">
```

**Pattern D — Method call:**
```html
<!-- Before -->
<div [ngStyle]="getTooltipPosition()">

<!-- After — inspect what the method returns, then decompose -->
<div [style.top.px]="tooltipY" [style.left.px]="tooltipX">
```
> For method calls, read the method implementation first. If it returns 2-3 properties, decompose into individual `[style.prop]` bindings. If the object is complex/dynamic, you can use `[style]` with a string value (`"top: 10px; left: 20px"`).

**Pattern E — Dynamic color:**
```html
<!-- Before -->
<span [ngStyle]="{ color: status(domObj).color }">

<!-- After -->
<span [style.color]="status(domObj).color">
```

### Step 3: Handle `[class]` + Static `class` Coexistence

When an element has both a static `class` attribute and you want to add `[class]="expr"`:

```html
<!-- WRONG — [class] overwrites static classes -->
<i class="fa fa-circle text-3xl" [class]="getStatusClass()">

<!-- Option A: merge into expression -->
<i [class]="'fa fa-circle text-3xl ' + getStatusClass()">

<!-- Option B: use individual bindings (preferred when few dynamic classes) -->
<i class="fa fa-circle text-3xl" [class.text-green]="isHealthy" [class.text-red]="!isHealthy">
```

### Step 4: Remove NgClass/NgStyle Import from Component/Module

After all template bindings are migrated:

1. **Standalone components** — Remove `NgClass`/`NgStyle` from the `imports` array in `@Component`:
```typescript
// Before
@Component({
  imports: [TranslateModule, NgClass, FormsModule],
})

// After
@Component({
  imports: [TranslateModule, FormsModule],
})
```

2. **NgModule-based components** — Remove `NgClass`/`NgStyle` from the module's `imports` array:
```typescript
// Before
import { NgClass, NgStyle } from '@angular/common';
@NgModule({
  imports: [NgClass, NgStyle, TranslateModule],
})

// After
@NgModule({
  imports: [TranslateModule],
})
```

3. **Remove the import statement** from `@angular/common` if `NgClass`/`NgStyle` were the only imports. If other symbols remain (e.g., `AsyncPipe`, `DecimalPipe`), just remove `NgClass`/`NgStyle` from the destructuring.

### Step 5: Verify

1. Run the build: `npx ng build` — check for template compilation errors
2. Visually verify the component in the browser — confirm classes/styles still apply correctly
3. Grep the file to confirm zero remaining `ngClass`/`ngStyle` references

---

## Edge Cases & Gotchas

### 1. `[class]` overwrites all static classes
Unlike `[ngClass]` which merges with existing classes, `[class]="expr"` **replaces** all classes. Use `[class.specific-class]="condition"` to safely add/remove individual classes alongside static ones.

### 2. Static `[ngStyle]` → plain `style` attribute
If the value is entirely static (e.g., `[ngStyle]="{ display: 'none' }"`), convert to a plain HTML `style` attribute instead of `[style.display]`.

### 3. Method calls returning objects
For `[ngClass]="getClasses()"` where the method returns `{ className: boolean }`, you must inspect the method and decompose into individual `[class.x]` bindings. The native `[class]` binding only accepts strings, not objects.

### 4. Kebab-case CSS properties
Use the same kebab-case in native bindings: `[style.font-size.px]="size"`, `[style.background-color]="color"`.

### 5. Multiple classes in a single conditional
```html
<!-- ngClass allowed this -->
[ngClass]="{ 'class-a class-b': condition }"

<!-- Native requires splitting -->
[class.class-a]="condition" [class.class-b]="condition"
```

---

## Codebase-Specific Notes

### High-Impact Repeated Patterns

1. **Loading blocker** (17 occurrences): `[ngClass]="{ 'nj-hide-blocker': !loading }"` → `[class.nj-hide-blocker]="!loading"`
2. **Active tab** (~20 occurrences): `[ngClass]="{ active: isActiveState(...) }"` → `[class.active]="isActiveState(...)"`
3. **Hidden table headers** (24 occurrences): `[ngStyle]="{ display: 'none' }"` → `style="display: none"`
4. **Bordered container** (5 occurrences): `[ngClass]="{ bordered: bordered }"` → `[class.bordered]="bordered"`
5. **Disabled state** (~10 occurrences): `[ngClass]="{ disabled: !enabled }"` → `[class.disabled]="!enabled"`

### Files with Inline Templates (3 files)
- `src/app/trees-viewer/nj-main/header/query-bar/buttons/querystring-reset.component.ts`
- `src/app/trees-viewer/nj-main/header/query-bar/buttons/query-saver-toggle.component.ts`
- `src/app/trees-viewer/nj-main/header/query-bar/buttons/query-history-toggle.component.ts`

These use `[ngClass]="{ active: queryService.getUnsavedQuery() }"` inside inline templates — apply the same Pattern 1 rule.

---

## Migration Order Recommendation

1. **Start with `[ngStyle]`** — only 14 files, 39 occurrences, mostly trivial (24 are static `display: none`)
2. **Then `[ngClass]` shared components** — `src/app/shared/components/` (high reuse, high impact)
3. **Then `[ngClass]` by module area** — administration, argos, trees-viewer, etc.
4. **Finally inline templates** — 3 `.ts` files with inline templates
