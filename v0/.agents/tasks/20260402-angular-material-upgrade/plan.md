# Angular Material 16 -> 17 Upgrade

## Context

The project uses Angular 17.3.10 but `@angular/material` and `@angular/cdk` are stuck at 16.2.14. This version mismatch can cause subtle runtime issues and prevents using Material 17 features. Note: there is a separate task for the full Material-to-PrimeNG migration (`20260401-material-to-primeng-migration`). This task covers the version upgrade to unblock compatibility while Material components are still in use.

**Important:** If the Material-to-PrimeNG migration is progressing quickly, this upgrade may be unnecessary — just remove Material entirely instead.

---

## Approach

### Step 1: Run Angular Update

```bash
ng update @angular/material@17 @angular/cdk@17
```

This handles:
- Version bumps in `package.json`
- Automated migration of deprecated APIs
- Removal of `legacy-*` prefixed imports (Material 15 introduced the MDC migration, 16 deprecated legacy, 17 removes it)

### Step 2: Fix Legacy Import Paths

The project may still use `MatLegacy*` imports from Material 15/16 migration. These are removed in Material 17:

- `MatLegacySelectModule` -> `MatSelectModule`
- `MatLegacyCheckboxModule` -> `MatCheckboxModule`
- `MatLegacyTooltipModule` -> `MatTooltipModule`
- `MatLegacyAutocompleteModule` -> `MatAutocompleteModule`
- `MatLegacyInputModule` -> `MatInputModule`
- `MatLegacyTableModule` -> `MatTableModule`
- `MatLegacyPaginatorModule` -> `MatPaginatorModule`
- `MAT_LEGACY_SELECT_CONFIG` -> `MAT_SELECT_CONFIG`

### Step 3: Style Adjustments

Material 17 fully uses MDC-based components. Check:
- Custom Material style overrides in `src/styles/vendor/material/material.scss`
- Component-level Material style overrides
- Spacing and sizing differences from MDC migration

---

## Scope

- ~107 TS files importing from `@angular/material`
- ~65 HTML templates using Material components
- Style overrides in `src/styles/vendor/material/`

---

## Verification

1. `ng update` completes without errors
2. `ng build` — compiles with Material 17
3. Visual check of Material components (selects, tables, dialogs, tooltips)
4. No console errors related to Material
5. `npm run test:prod` — tests pass
