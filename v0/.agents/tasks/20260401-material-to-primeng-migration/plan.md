# Angular Material to PrimeNG Migration Plan

## Context

The njams-frontend project (Angular 17.3.10) currently uses both Angular Material 16.2.14 (legacy) and PrimeNG 17.18.0 side-by-side. PrimeNG is already the dominant UI library (295+ imports), while Material remains in ~107 TS files and ~65 HTML templates. The goal is to remove all Angular Material usages and replace them with PrimeNG equivalents, then uninstall `@angular/material`.

---

## Inventory Summary

| Material Component | HTML Files | PrimeNG Replacement |
|---|---|---|
| `mat-table` + `matSort` | 29 | `p-table` + `pSortableColumn` + `p-sortIcon` |
| `mat-select` + `mat-option` | 34 | `p-dropdown` |
| `mat-autocomplete` + `matInput` | 4 (+1 matInput only) | `p-autoComplete` |
| `mat-paginator` | 2 | `p-table` built-in `[paginator]="true"` |
| `matTooltip` | 2 | `pTooltip` (already used elsewhere) |
| CDK `SelectionModel` | 21 TS files | `p-table` `[(selection)]` + `p-tableCheckbox` |
| CDK Virtual Scroll | 1 TS file (tree) | Keep `@angular/cdk` (independent of Material) |
| Unused imports (dialog, checkbox, icon, button modules) | 2 modules | Just remove |

---

## Phase 0: Dead Code Cleanup

Remove confirmed unused Material module imports (templates already use PrimeNG).

**Files:**
- `src/app/shared/components/dialogs/nj-dialog/nj-dialog.module.ts` - Remove `MatIconModule`, `MatButtonModule`, `MatDialogModule` (template uses `p-button`)
- `src/app/shared/components/nj-same-process-list/nj-same-process-list.module.ts` - Remove `MatLegacyCheckboxModule` (no `mat-checkbox` in template)

**Verify:** `ng build` succeeds, dialogs and same-process-list still work.

---

## Phase 1: Tooltip Migration

Replace 2 remaining `matTooltip` usages with `pTooltip`.

**Files:**
- `src/app/shared/components/nj-extracts/nj-extract-expression/nj-extract-expression.component.html` - `[matTooltip]` -> `[pTooltip]` + `tooltipPosition="bottom"`
- `src/app/shared/components/nj-extracts/nj-extracts.component.html` - same
- `src/app/shared/components/nj-extracts/nj-extracts.module.ts` - Remove `MatLegacyTooltipModule`, add `TooltipModule` from `primeng/tooltip` if not present

**Verify:** Hover tooltips appear on extract attributes.

---

## Phase 2: Select/Dropdown Migration

Replace all `mat-select` + `mat-option` with PrimeNG `p-dropdown`.

### Mapping

| Material | PrimeNG |
|---|---|
| `<mat-select [(ngModel)]="x" (selectionChange)="fn()">` | `<p-dropdown [(ngModel)]="x" (onChange)="fn()" [options]="items" optionLabel="label" optionValue="value" />` |
| `<mat-option *ngFor="let i of items" [value]="i.val">{{i.name}}</mat-option>` | Converted to `[options]` array on `p-dropdown` |
| `<mat-optgroup label="group">` | `[group]="true"` + `optionGroupLabel` + `optionGroupChildren` |
| `[disabled]` on mat-select | `[disabled]` on p-dropdown |

### 34 HTML files + 16 module files

Module change: Replace `MatLegacySelectModule`/`MatSelectModule` with `DropdownModule` from `primeng/dropdown`.

**16 module files to update:**
1. `src/app/argos/rule-overview/link-components/link-components.module.ts`
2. `src/app/argos/dashboard/editor/component-configuration/chart-configuration/chart-configuration.module.ts`
3. `src/app/argos/dashboard/editor/component-configuration/cell-details/cell-details.module.ts`
4. `src/app/argos/dashboard/editor/link-configuration/link-configuration.module.ts`
5. `src/app/rules/rules-menu/rule-set-view/rule-set-view.module.ts`
6. `src/app/rules/rules-menu/rule-set-view/rule-view/rule-condition/rule-condition.module.ts`
7. `src/app/rules/rules-menu/rule-set-view/rule-view/rules-action/rules-action.module.ts`
8. `src/app/administration/roles-admin/roles-admin-view-settings/roles-admin-view-settings.module.ts`
9. `src/app/administration/authentication-configuration/openid-connect.module.ts`
10. `src/app/trees-viewer/properties/domain-objects/settings/properties-domain-objects-settings.module.ts`
11. `src/app/trees-viewer/nj-main/header/query-bar/query-bar.module.ts`
12. `src/app/trees-viewer/nj-custom-report/nj-custom-report-tile-wizard/nj-custom-report-tile-wizard.module.ts`
13. `src/app/shared/components/nj-date-time/nj-date-time.module.ts`
14. `src/app/shared/components/nj-extracts/nj-extracts.module.ts`
15. `src/app/error-list/error-list.module.ts`
16. `src/app/error-list/email-alerts/email-alerts-edit/email-alerts-edit.module.ts`

**Key files:**
- `src/app/shared/components/nj-date-time/nj-date-time.component.html` - month selector (high-risk shared component, test thoroughly)
- `src/app/administration/data-provider-admin/data-provider-admin-edit/data-provider-admin-edit.component.html` - uses `mat-optgroup`
- All remaining files in: user/, argos/, rules/, administration/, trees-viewer/, shared/, error-list/, feature/

**After completion:** Delete `src/app/material.module.ts` and remove its import from `src/app/app.module.ts`.

**Verify per batch:** Dropdown opens, options display, selection binds to model, `(onChange)` fires, disabled state works. Test nj-date-time month switching specifically.

---

## Phase 3: Autocomplete Migration

Replace `mat-autocomplete` + `matInput` with PrimeNG `p-autoComplete`.

### Mapping

| Material | PrimeNG |
|---|---|
| `<input matInput [matAutocomplete]="auto">` + `<mat-autocomplete #auto>` | `<p-autoComplete [(ngModel)]="x" [suggestions]="filtered" (completeMethod)="filter($event)" />` |
| `[displayWith]="fn"` | `[field]="'displayField'"` or `ng-template pTemplate="item"` |

### 4 HTML files + TS changes

- `src/app/rules/rules-menu/rule-set-view/rule-view/rule-condition/rule-condition.component.html`
- `src/app/rules/rules-menu/rule-set-view/rule-view/rules-action/rules-action.component.html`
- `src/app/administration/jndi-admin/jndi-admin-edit/jndi-admin-edit.component.html`
- `src/app/trees-viewer/nj-main/nj-process-details/follow-up/follow-up.component.html`

**TS changes:** Each component needs a `filter(event: AutoCompleteCompleteEvent)` method that populates a `filteredSuggestions` array (PrimeNG uses event-driven filtering vs Material's pre-computed approach).

**Module change:** Replace `MatLegacyAutocompleteModule` + `MatLegacyInputModule` with `AutoCompleteModule` from `primeng/autocomplete`.

**Verify:** Type in field -> suggestions appear, selection binds, follow-up displays user name not ID.

---

## Phase 4: Simple Table Migration (no SelectionModel)

Migrate 8 Material tables that don't use `SelectionModel`.

### Mapping

| Material | PrimeNG |
|---|---|
| `<table mat-table [dataSource]="ds" matSort>` | `<p-table [value]="items" sortField="col" [sortOrder]="1">` |
| `<ng-container matColumnDef="col">` + `<th *matHeaderCellDef mat-sort-header>` + `<td *matCellDef="let row">` | `<ng-template pTemplate="header"><tr><th pSortableColumn="col">Label <p-sortIcon field="col"/></th></tr></ng-template>` + `<ng-template pTemplate="body" let-row><tr><td>{{row.col}}</td></tr></ng-template>` |
| `MatTableDataSource` | Remove; bind raw array to `[value]` |
| `@ViewChild(MatSort)` + `ds.sort = sort` | Remove; PrimeNG handles sorting internally |
| `sortingDataAccessor` | `[customSort]="true"` + `(sortFunction)="customSort($event)"` |

### 8 files:
1. `src/app/administration/roles-admin/roles-admin-list/roles-admin-list.component.html`
2. `src/app/administration/message-processing/logmessage-statistics/details/details.component.html`
3. `src/app/administration/message-processing/message-processing-list/cluster-nodes-status/cluster-nodes-status.component.html`
4. `src/app/administration/message-processing/message-processing-list/data-provider/data-provider.component.html`
5. `src/app/administration/message-processing/message-processing-list/bulk-processing-statistics/bulk-processing-statistics.component.html`
6. `src/app/trees-viewer/nj-main/nj-process-details/nj-trace-table/nj-trace-table.component.html`
7. `src/app/trees-viewer/nj-custom-report/nj-reports/nj-reports-top-10/nj-reports-top-10.component.html`
8. `src/app/feature/administration/job/job-execution-list/job-execution-list.component.html`

**Reference pattern:** `src/app/feature/administration/user-management/sessions/sessions.component.html` (existing PrimeNG table with sort + selection)

**Verify:** All columns render, sorting works (click header toggles asc/desc), custom sort logic preserved for data-provider and cluster-nodes-status.

---

## Phase 5: Table Migration with SelectionModel (21 files)

Replace `SelectionModel` from `@angular/cdk/collections` with PrimeNG's built-in table selection.

### Mapping

| Material + CDK | PrimeNG |
|---|---|
| `selection = new SelectionModel<T>(true, [])` | `selectedItems: T[] = []` |
| `selection.isSelected(row)` | Handled internally by `[(selection)]` |
| `selection.toggle(row)` | `p-tableCheckbox` handles this |
| `selection.selected` | `this.selectedItems` |
| `selection.isEmpty()` / `hasValue()` | `this.selectedItems.length === 0` / `> 0` |
| `selection.clear()` | `this.selectedItems = []` |
| `masterToggle()` / `isAllSelected()` | `p-tableHeaderCheckbox` handles automatically |
| Custom checkbox HTML | `<p-tableCheckbox [value]="row" />` |

Each table needs `dataKey="uniqueField"` for row identity tracking.

### Sub-batches:
1. **Administration** (5): roles-admin-system-privilege-list, roles-admin-user-list, user-admin-roles-list, data-provider-admin, + one more
2. **Argos** (3): add-category, rule-overview, link-components (complex: 2 tables + 2 paginators)
3. **Trees-viewer** (8): settings tables (business-objects, business-services, domain-objects, query-objects), activity-list, events, trace-settings, custom-report-tab-edit
4. **Error-list** (3): attributes-picker, email-alerts-edit, error-list-events
5. **Remaining** (3): notification-list, rules-list, nj-same-process-list

**Special cases:**
- `link-components`: 2 tables + 2 paginators in one template; migrate together
- `nj-same-process-list`: SelectionModel consumed by `replay-as.component.ts`; update both simultaneously

**Module change:** Replace `MatLegacyTableModule`/`MatSortModule` with `TableModule` from `primeng/table`. Remove `SelectionModel` import.

**Reference:** `src/app/feature/administration/user-management/sessions/sessions.component.html` and `src/app/administration/deployment/failsafe/failsafe.component.html`

**Verify:** Checkbox selection, header checkbox select-all, bulk action buttons enabled/disabled correctly, row data displays.

---

## Phase 6: Paginator Migration (alongside Phase 5)

The 2 standalone `mat-paginator` instances are in templates being migrated in Phase 5. Use PrimeNG's built-in `[paginator]="true" [rows]="50"` on the `p-table` instead.

**Files:**
- `src/app/argos/rule-overview/link-components/link-components.component.html`
- `src/app/error-list/email-alerts/email-alerts-list/email-alerts-list.component.html`

Remove `MatLegacyPaginatorModule` from their modules.

---

## Phase 7: Final Cleanup

1. **Delete** `src/app/material.module.ts` (if not already done in Phase 2)
2. **Remove** `MaterialModule` from `src/app/app.module.ts`
3. **Delete** `src/styles/vendor/material/material.scss` (314 lines)
4. **Remove** `@import 'vendor/material/material'` from `src/styles.scss`
5. **Audit:** Grep for `@angular/material` across all `*.ts` files -- expect zero hits
6. **Keep** `@angular/cdk` -- needed for virtual scroll in `src/app/trees-viewer/tree/tree.component.ts`
7. **Uninstall:** `npm uninstall @angular/material`
8. **Build + full regression test**

**Verify:** `ng build --configuration production` succeeds, no Material references remain, CDK virtual scroll in tree still works, full application smoke test.

---

## Key Risks

| Risk | Mitigation |
|---|---|
| nj-date-time month selector regression | Test all date picker instances across the app after Phase 2 |
| SelectionModel cross-component coupling (same-process-list -> replay-as) | Update both components in same commit |
| Custom sort functions break | Use `[customSort]="true"` + `(sortFunction)`, test each sortable column |
| CDK overlay styles removed affect PrimeNG | Verify PrimeNG overlays (dropdowns, dialogs) still work after deleting material.scss |
| link-components dual table complexity | Migrate both tables + paginators together in one commit |
