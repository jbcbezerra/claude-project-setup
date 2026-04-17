# Phase 2: jQuery Ecosystem Removal

## Context

jQuery 3.5.1, jQuery UI 1.12.1, and Selectize 0.12.4 are legacy dependencies exposed globally via webpack `expose-loader`. They add ~90 KB gzipped to the bundle and represent an outdated DOM manipulation paradigm incompatible with Angular's change detection. PrimeNG v17.18.0 is already in the project and provides replacements for Selectize. Angular CDK DragDrop replaces jQuery UI sortable.

**Dependencies:** Requires `@angular/cdk` update from 16.2.14 → 17.x.
**Estimated effort:** 3–5 days.
**Bundle savings:** ~90 KB gzipped.

---

## Prerequisite: Update @angular/cdk to 17.x

The current `@angular/cdk` is v16.2.14 but Angular is v17. Update to match:
```
npm install @angular/cdk@17
```

---

## 2A. Replace Selectize with PrimeNG (17 files)

### Current implementation

**Wrapper component:** `src/shared/directives/selectize/selectize.component.ts`
- Standalone Angular component wrapping jQuery selectize
- Uses `$(this.element.nativeElement).selectize(settings)` internally
- Inputs: `settings`, `options`, `value`, `enabled`
- Output: `ngModelChange`
- Config pattern: `{ valueField, labelField, options, maxItems, plugins, create }`

### Replacement mapping

| Selectize config | PrimeNG equivalent | Component |
|-----------------|-------------------|-----------|
| `maxItems: 1` (single select) | `p-dropdown` | `DropdownModule` |
| `maxItems: n` (multi select) | `p-multiSelect` | `MultiSelectModule` |
| `create: true` (allow new items) | `p-autoComplete` with `forceSelection="false"` | `AutoCompleteModule` |
| `valueField` | `optionValue` | — |
| `labelField` | `optionLabel` | — |
| `options` | `[options]` | — |
| `placeholder` | `placeholder` | — |
| `plugins: ['remove_button']` | Built-in chip display in multiSelect | — |

### Steps

1. **Audit all selectize usages** — grep for `<selectize` and `<app-selectize` in templates to find every instance. For each, determine if it's single-select, multi-select, or creatable.

2. **For each component using selectize:**
   - Replace `<selectize>` / `<app-selectize>` with `<p-dropdown>` or `<p-multiSelect>`
   - Update the component's module/imports to include the PrimeNG module
   - Map the `settings` object properties to PrimeNG input bindings
   - Replace `(ngModelChange)` event binding with PrimeNG's `(onChange)` or keep `[(ngModel)]`
   - Ensure `FormsModule` is imported where needed

3. **Remove selectize wrapper:**
   - Delete `src/shared/directives/selectize/selectize.component.ts`
   - Delete associated module file if present
   - Remove selectize CSS from `src/styles/vendor.scss` (`@import 'selectize/dist/css/selectize.css'`)

4. **Package cleanup:**
   - Remove `selectize` from `dependencies`
   - Remove `@types/selectize` from `devDependencies`
   - Remove expose-loader rule for selectize from `webpack.config.js` (lines 154–164)
   - Remove `selectize` from `allowedCommonJsDependencies` in `angular.json`

### Key files to modify
- `src/shared/directives/selectize/selectize.component.ts` — DELETE
- `src/styles/vendor.scss` — remove selectize CSS import
- `webpack.config.js` — remove selectize expose-loader
- `angular.json` — remove from allowedCommonJsDependencies
- All ~17 consuming component templates and their modules

---

## 2B. Replace jQuery UI Sortable with Angular CDK DragDrop (3 files)

### Current implementation

Three files use `$(element).sortable()` from jQuery UI:

1. **`src/trees-viewer/nj-custom-report/nj-custom-report-tab/sortable.directive.ts`**
   - Directive that calls `$(el).sortable({ stop: callback })`
   - Used for reordering report tiles

2. **`src/argos/navigation-list-sort-watcher.ts`**
   - Service that calls `$(selector).sortable()` imperatively
   - Used for reordering navigation categories

3. **`src/argos/category/category-sort-watcher.ts`**
   - Service that calls `$(selector).sortable()` imperatively
   - Used for reordering dashboard tabs

### Replacement approach

**For the sortable directive:**
- Convert to use `CdkDragDrop` module
- Parent template uses `cdkDropList` on the container, `cdkDrag` on items
- The `(cdkDropListDropped)` event replaces the `stop` callback
- Use `moveItemInArray()` from `@angular/cdk/drag-drop` for reorder logic

**For the service-based sort watchers:**
- These imperatively query the DOM with jQuery selectors — this pattern doesn't work with CDK
- Refactor: move the sortable behavior into the template of the parent component using `cdkDropList`/`cdkDrag`
- The service receives reorder events from the component instead of manipulating DOM directly
- The component calls the service method on `(cdkDropListDropped)` event

### Steps

1. Import `DragDropModule` from `@angular/cdk/drag-drop` in relevant modules

2. **Refactor `sortable.directive.ts`:**
   - Replace jQuery sortable with CDK drag-drop directives in the parent template
   - Handle `(cdkDropListDropped)` event to call `moveItemInArray()`
   - Remove the directive if it's no longer needed (logic moves to template)

3. **Refactor `navigation-list-sort-watcher.ts` and `category-sort-watcher.ts`:**
   - Find the parent components that use these services
   - Add `cdkDropList` + `cdkDrag` to their templates
   - On drop event, call the service's save/reorder method
   - Remove imperative jQuery DOM manipulation from the services

4. Remove jQuery UI datepicker styles from `vendor.scss` (`@import 'ui-datepicker'`)

---

## 2C. Replace jQuery selector in JointJS rect.ts

### Current usage
`src/argos/dashboard/editor/joint/rect.ts` line ~634:
```typescript
const agNodeGroup = $(`g[model-id="${cell.id}"]`).find('.ag-node-group');
```

### Replacement
```typescript
const agNodeGroup = document.querySelector(`g[model-id="${cell.id}"] .ag-node-group`);
```

Also remove `declare const $: JQueryStatic;` from this file.

---

## 2D. Webpack & Package Cleanup

### webpack.config.js
- Remove expose-loader rules for `jquery` (lines 138–153)
- Remove expose-loader rules for `selectize` (lines 154–164)

### angular.json
- Remove `jquery` from `allowedCommonJsDependencies`

### src/app/types/typings.d.ts
- Remove `declare const $: JQueryStatic;`
- Remove `declare const selectize: any;`
- Remove `declare const Selectize: any;`

### src/app/app.module.ts
- Remove `import 'jquery';`
- Remove `import 'jquery-ui-bundle';`
- Remove `import 'selectize';`

### package.json
- Remove from dependencies: `jquery`, `jquery-ui-bundle`, `selectize`
- Remove from devDependencies: `@types/jquery`, `@types/jqueryui`, `@types/selectize`, `@types/jquery.contextmenu`

**Note:** `jquery` will remain in `node_modules` as a transitive dependency of `jointjs`. This is expected until JointJS drops jQuery (Phase 5).

---

## Verification

1. `npm run build` — no compilation errors
2. `npm run test` — all unit tests pass
3. **Manual testing (critical):**
   - All dropdown/select components throughout the app — verify options load, selection works, search/filter works
   - Custom report tile reordering — drag and drop works
   - Dashboard navigation category reordering
   - Dashboard tab reordering
   - Dashboard editor — JointJS diagrams render correctly without global jQuery
4. Check browser console for any jQuery-related errors
