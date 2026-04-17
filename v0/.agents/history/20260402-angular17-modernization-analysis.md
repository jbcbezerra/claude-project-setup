# Session: Angular 17 Modernization Analysis

**Date:** 2026-04-02
**Goal:** Analyze the njams-frontend Angular 17 project for legacy code patterns inherited from AngularJS migration, and create detailed modernization task plans.

---

## Claude Session Brain

### Session transcript
- `/home/joao/.claude/projects/-home-joao-Desktop-server/7660f100-ca74-45c8-8d4e-c5409e1ec9e0.jsonl`

### Session working directory
- `/home/joao/.claude/projects/-home-joao-Desktop-server/7660f100-ca74-45c8-8d4e-c5409e1ec9e0/`

---

## Summary

Performed a comprehensive codebase analysis of the Angular 17.3.10 project to identify legacy patterns, assess modernization priorities, and create actionable task plans. Key findings:

- **Build config:** AOT disabled, buildOptimizer off, Material 16 mismatched with Angular 17
- **Code patterns:** 456+ `any` types, 235+ manual subscriptions, 125 manual unsubscribes, near-zero async pipe usage, only 1 OnPush component, 52 ViewEncapsulation.None, mixed standalone/NgModule (185/180)
- **AOT blockers investigated in depth:** Custom Parser extending `@angular/compiler`, `ComponentFactoryResolver` in dialog service, runtime `Compiler.compileModuleAndAllComponentsAsync()`, dynamic `Component()` decorator in custom reports, `new Function()` usage, ngx-toastr string-based injection token

Created 9 task plans in `.agents/tasks/`:
1. `20260402-aot-build-configuration` — AOT enablement with 6 blocker fixes
2. `20260402-control-flow-migration` — *ngIf/*ngFor to @if/@for (automated)
3. `20260402-ngmodule-to-standalone-migration` — 180 modules, leaf-first
4. `20260402-reactive-patterns-modernization` — subscriptions, async pipe, signals, DoCheck
5. `20260402-moment-to-dayjs-consolidation` — 67 files, ~300KB savings
6. `20260402-angular-material-upgrade` — Material 16->17 alignment
7. `20260402-type-safety-eslint` — ESLint setup, any reduction, strict TS
8. `20260402-view-encapsulation-audit` — 52 components
9. `20260402-inject-function-standardization` — constructor DI to inject()

---

## Key Decisions

- AOT enablement requires fixing 6 critical blockers before flipping the flag — custom Parser, ComponentFactoryResolver, runtime Compiler, dynamic Component decorator, error-list plugins, toastr string token
- UI-Router migration is out of scope (separate existing task)
- Karma-to-Jest migration is out of scope (separate effort)
- Material 16->17 upgrade may be skipped if Material-to-PrimeNG migration completes first
- `any` reduction is gradual (fix-on-touch), not a mass replacement
- Control flow migration is automated via Angular schematic
