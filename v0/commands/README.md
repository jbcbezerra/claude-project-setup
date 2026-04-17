# Project Commands

Custom slash commands available in this project.

## /migrate-api

Migrates a single old Promise-based API endpoint from `src/app/api/manual/endpoints/` to the new Observable-based HttpClient pattern at `src/app/core/services/api/`.

**Usage:**
```
/migrate-api <endpoint-name>
```

**Examples:**
```
/migrate-api expression
/migrate-api configuration
/migrate-api notification
/migrate-api usermanagement/roles
```

**What it does:**

1. Reads the old endpoint and catalogs all methods
2. Checks if a new service already exists (partial migration)
3. Creates or updates the new `<Domain>ApiService` following project conventions
4. Finds and updates ALL consumers — converts Promise chains (`.then`/`.catch`/`await`) to Observable patterns (`.subscribe`/`.pipe`) with `takeUntilDestroyed`
5. Switches consumer injection from constructor to `inject()`
6. Removes the old endpoint from `api.module.ts` if no consumers remain
7. Runs `ng build` to validate

**References:**
- Full workflow: `.agents/workflows/api-migration-workflow.md`
- Service conventions: `.agents/rules/api-services.md`
- Component conventions: `.agents/rules/component-patterns.md`

---

## /migrate-material

Replaces Angular Material component usage with PrimeNG equivalents in a specific component or migration phase.

**Usage:**
```
/migrate-material <phase-or-component>
```

**Examples:**
```
/migrate-material phase0
/migrate-material phase2
/migrate-material src/app/shared/components/nj-date-time/nj-date-time.component.html
/migrate-material nj-extracts
```

**What it does:**

1. Reads the target component (or all components in a phase) and catalogs Material usages
2. Reads existing PrimeNG reference patterns from the codebase
3. Replaces Material components in the HTML template:
   - `mat-select` + `mat-option` → `p-dropdown`
   - `mat-table` + `matSort` → `p-table` + `pSortableColumn` + `p-sortIcon`
   - `mat-autocomplete` → `p-autoComplete`
   - `matTooltip` → `pTooltip`
   - `mat-paginator` → `p-table` built-in `[paginator]`
4. Updates TypeScript: removes `MatTableDataSource`, `SelectionModel`, `@ViewChild(MatSort)`, replaces with PrimeNG patterns
5. Updates the module: swaps Material modules for PrimeNG modules
6. Handles cross-component coupling (e.g., `SelectionModel` shared between parent/child)
7. Runs `ng build` to validate

**References:**
- Migration plan: `.agents/tasks/20260401-material-to-primeng-migration/plan.md`
- PrimeNG table reference: `src/app/feature/administration/user-management/sessions/sessions.component.html`
- PrimeNG table simple: `src/app/administration/deployment/failsafe/failsafe.component.html`
- PrimeNG dropdown reference: `src/app/administration/indexer/indexer-connection/index-size/index-size.component.html`

---

## /save-session

Saves a pointer to the current Claude session's brain files (transcript + working directory) so a future agent can reload the full context and continue where this session left off.

**Usage:**
```
/save-session <short-title>
```

**Examples:**
```
/save-session api-migration-setup
/save-session fix-auth-flow
/save-session refactor-tree-component
```

**What it does:**

1. Finds the current session's `.jsonl` transcript and working directory in `~/.claude/projects/`
2. Summarizes what was accomplished, decided, and created during this session
3. Writes a history file to `.agents/history/<YYYYMMDD>-<title>.md`
4. Updates `.agents/registry.md`

**To reload a past session in a new conversation:**
> Read `.agents/history/<session-file>.md`, then load the session transcript to understand what was explored, decided, and built.
