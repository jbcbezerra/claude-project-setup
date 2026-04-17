# .agents Registry

## Workflows
- [API Migration Workflow](workflows/api-migration-workflow.md) — Step-by-step playbook for migrating old Promise-based API endpoints to new Observable-based HttpClient services
- [NgClass/NgStyle Migration Workflow](workflows/completed/ngclass-ngstyle-migration-workflow.md) — ~~Migrate [ngClass]/[ngStyle] directives to native [class]/[style] bindings~~ COMPLETED

## Rules
- [API Services](rules/api-services.md) — Conventions for creating API services in core/services/api/
- [Error Handling](rules/error-handling.md) — Logging via LoggerService and RxJS catchError operator conventions
- [inject() Function](rules/inject-function.md) — Always use inject() for DI in Angular-decorated classes, never constructor injection
- [Control Flow](rules/control-flow.md) — Use @if/@for/@switch, meaningful track expressions, no CommonModule for structural directives
- [Native Class & Style Bindings](rules/native-class-style-bindings.md) — Use [class.x]/[style.x] bindings, never NgClass/NgStyle directives
- [Day.js Usage](rules/dayjs-usage.md) — Day.js conventions: plugin init, immutability, no leaking Dayjs types
- [Datetime Centralization](rules/datetime-centralization.md) — Utility layer, TimezoneService, pipes, chart tooltip rules
- [Date Picker Consolidation](rules/date-picker-consolidation.md) — Use nj-date-time-picker only; deprecated: nj-date-time, p-calendar
- [Query Date Service](rules/query-date-service.md) — Single source of truth for query date logic; deprecates TimeRangeCalculatorService, QueryTimepickerEntriesService, and QueryService date methods
- [State Services](rules/state-services.md) — Conventions for signal-based state management services
- [Component Patterns](rules/component-patterns.md) — How components inject services, subscribe, and clean up

## Context
- [API Layer Architecture](context/api-layer-architecture.md) — Old vs new HTTP API layers, request flows, migration status

## Knowledge
- [Parallel Subagent Tips](knowledge/parallel-subagent-tips.md) — Lessons learned from parallel worktree migrations: grouping, conflict avoidance, git-svn constraints

## Decisions
- [ADR-20260401: API Layer Migration](decisions/ADR-20260401-api-layer-migration.md) — Why: duplicated code, fragmented errors, manual XHR, no tree-shaking

## History
- [20260401 UIRouter Migration Analysis](history/20260401-uirouter-migration-analysis.md) — Full codebase scan and migration blueprint for @uirouter/angular → @angular/router
- [20260401 Material to PrimeNG Migration Plan](history/20260401-material-to-primeng-migration-plan.md) — Codebase analysis and phased plan to replace all Angular Material with PrimeNG v17
- [20260401 TailwindCSS Button Component Plan](history/20260401-tailwindcss-button-component-plan.md) — Plan to introduce TailwindCSS and create first nj-button component with Cypress CT
- [20260402 Angular 17 Modernization Analysis](history/20260402-angular17-modernization-analysis.md) — Full legacy pattern audit and 9 modernization task plans with AOT blocker deep-dive
- [20260402 File Architecture Redesign](history/20260402-file-architecture-redesign.md) — Designed core/domain/shared architecture with standardized subfeature pattern and 5-phase migration plan
- [20260402 Material to PrimeNG Execution](history/20260402-material-to-primeng-execution.md) — Full execution of Angular Material → PrimeNG migration: all selects, tables, autocompletes, tooltips migrated and @angular/material uninstalled
- [20260403 Error Handling Tasks 01-03](history/20260403-error-handling-tasks-01-03.md) — Centralized logging migration, RxJS operator standardization, global ErrorHandler creation
- [20260404 Error Handling Task 04](history/20260404-error-handling-task-04.md) — Eliminate silent catches, safeJsonParse utility, bare JSON.parse wrapping
- [20260404 Datetime Centralization Plan](history/20260404-datetime-centralization-plan.md) — 19-agent codebase analysis and 8-phase plan to centralize all datetime handling (~20-26d effort)
- [20260404 Datetime Centralization Phases 1-4](history/20260404-datetime-centralization-phases-1-4.md) — Executed Phases 1-4: utilities, TimezoneService, pipe consolidation, chart tooltips (228 tests passing)

## Tasks
- [TailwindCSS Button Component](tasks/20260401-tailwindcss-button-component/plan.md) — Introduce TailwindCSS v3 and create reusable nj-button with Cypress component tests
- [UIRouter to Angular Router Migration](tasks/20260401-uirouter-to-angular-router-migration/plan.md) — Comprehensive analysis and migration blueprint for @uirouter/angular → @angular/router
- [Material to PrimeNG Migration](tasks/20260401-material-to-primeng-migration/plan.md) — Phased plan to remove all @angular/material usages and replace with PrimeNG v17 components
- [AOT & Build Configuration](tasks/20260402-aot-build-configuration/plan.md) — Enable AOT compilation after fixing 6 critical blockers (Parser, CFR, Compiler, dynamic components, toastr)
- [NgModule to Standalone Migration](tasks/20260402-ngmodule-to-standalone-migration/plan.md) — Convert ~180 NgModule components to standalone, leaf-first
- [Reactive Patterns Modernization](tasks/20260402-reactive-patterns-modernization/plan.md) — takeUntilDestroyed, async pipe, Promise→Observable, DoCheck removal, signals
- [Moment to Day.js Consolidation](tasks/20260402-moment-to-dayjs-consolidation/plan.md) — Migrate 67 files from moment.js to dayjs (~300KB bundle savings)
- [Angular Material 16→17 Upgrade](tasks/20260402-angular-material-upgrade/plan.md) — Version alignment (skip if PrimeNG migration completes first)
- [Type Safety & ESLint](tasks/20260402-type-safety-eslint/plan.md) — ESLint setup, gradual any reduction, strict TypeScript options
- [ViewEncapsulation Audit](tasks/20260402-view-encapsulation-audit/plan.md) — Categorize and fix 52 components using ViewEncapsulation.None
- [Native Replacements: lodash, uuid, file-saver](tasks/20260402-native-replacements-lodash-uuid-filesaver/plan.md) — Replace 3 utility libs with native browser APIs (~28KB savings)
- [jQuery Ecosystem Removal](tasks/20260402-jquery-ecosystem-removal/plan.md) — Remove jquery, jquery-ui, selectize; replace with PrimeNG + CDK DragDrop (~90KB savings)
- [oidc-client → oidc-client-ts](tasks/20260402-oidc-client-migration/plan.md) — Replace deprecated OIDC library with maintained TypeScript fork
- [Ace Editor & Highcharts Updates](tasks/20260402-ace-highcharts-updates/plan.md) — Update ace-builds 1.4→latest, ace-diff 2→3, highcharts to latest
- [Specialized Library Cleanup](tasks/20260402-specialized-lib-cleanup/plan.md) — Fix JointJS types, replace pegjs→peggy, document keep decisions
- [File Architecture Redesign](tasks/20260402-file-architecture-redesign/plan.md) — Redesign to core/domain/shared with data-access/entities/state/component pattern per subfeature
- [Datetime Centralization](tasks/20260404-datetime-centralization/plan.md) — Centralize all datetime handling: utilities, TimezoneService, pipes, pickers, query dates (~20-26d)

## Commands
- [/migrate-api](../../.claude/commands/migrate-api.md) — Migrate a Promise-based XHR endpoint to Observable-based HttpClient service
- [/migrate-material](../../.claude/commands/migrate-material.md) — Replace Angular Material components with PrimeNG equivalents (by phase or component)
- [/save-session](../../.claude/commands/save-session.md) — Save session context for future agent continuation
- [/load-session](../../.claude/commands/load-session.md) — Load a previous session's context from history to continue work
- [Project Commands README](../../.claude/commands/README.md) — Usage docs for all commands
